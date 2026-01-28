#include "Server.hpp"
#include <iostream>
#include <string>
#include <cerrno>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <fcntl.h>

Server::Server(const char* port, const char* password): listener(-1),  port(port), password(password), cmdHandler(nicknames, *this) {}

Server::~Server() {}

int		Server::getListenerSocket()
{
	int listener;
	int yes = 1;
	int rv;
	struct addrinfo hints, *res, *p;

	memset(&hints, 0, sizeof hints);
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_flags = AI_PASSIVE;

	if ((rv = getaddrinfo(NULL, port, &hints, &res)) != 0) {
		std::cerr << "getaddrinfo: " << gai_strerror(rv) << std::endl;
		return -1;
	}

	for (p = res; p != NULL; p = p->ai_next) {
		listener = socket(p->ai_family, p->ai_socktype, p->ai_protocol);
		if (listener < 0) {
			std::cerr << "socket: " << strerror(errno) << std::endl;
			continue;
		}

		if (setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int)) < 0) {
			std::cerr << "setsockopt: " << strerror(errno) << std::endl;
			close(listener);
			continue;
		}

		if (bind(listener, p->ai_addr, p->ai_addrlen) < 0) {
			std::cerr << "bind: " << strerror(errno) << std::endl;
			close(listener);
			continue;
		}
		break;
	}
	freeaddrinfo(res);

	if (p == NULL)
		return -1;
	if (listen(listener, BACKLOG) == -1)
		return -1;
	return listener;
}

int		Server::makeSocketNonblocking(int fd)
{
	int	flags = fcntl(fd, F_GETFL, 0);
	if (flags == -1) {
		std::cerr << "fcntl F_GETFL: " << strerror(errno) << std::endl;
		return -1;
	}

	flags |= O_NONBLOCK;
	if (fcntl(fd, F_SETFL, flags) == -1) {
		std::cerr << "fcntl F_SETFL: " << strerror(errno) << std::endl;
		return -1;
	}
	return 0;
}

void	Server::handleNewConnection()
{
	struct sockaddr_storage client_addr;
	socklen_t client_len = sizeof(client_addr);

	int new_fd = accept(listener, (struct sockaddr *)&client_addr, &client_len);
	if (new_fd < 0) {
		std::cerr << "accept: " << strerror(errno) << std::endl;
		return;
	}

	if (makeSocketNonblocking(new_fd) == -1) {
		close(new_fd);
		return;
	}

	pollfd client_pollfd;
	client_pollfd.fd = new_fd;
	client_pollfd.events = POLLIN;
	client_pollfd.revents = 0;
	fds.push_back(client_pollfd);

	clients[new_fd] = Client(new_fd);
	std::cout << "New client connected: fd " << new_fd << std::endl;
}

bool	Server::handleClientEvent(size_t index)
{
	Client& client = clients[fds[index].fd];
	bool should_close = false;

	if (fds[index].revents & POLLIN) {
		if (!client.handle_recv()) {
			should_close = true;
		} else {
			std::string message;
			while (client.extractMessage(message)) {
				processMessage(client, message);
			}

			if (client.hasWriteData()) {
				fds[index].events |= POLLOUT;
			}
		}
	}

	if (fds[index].revents & POLLOUT) {
		if (!client.handle_send()) {
			should_close = true;
		} else {
			if (!client.hasWriteData()) {
				fds[index].events = POLLIN;
			}
		}
	}

	if (should_close) {
		closeClient(index);
		return false;
	}
	return true;
}


void	Server::processMessage(Client& client, const std::string& message)
{
	std::cout << "Received from fd " << client.getFd() << ": " << message << std::endl;

	Message msg(message);
	cmdHandler.handleCommand(client, msg);
}

// Channel management
Channel* Server::getChannel(const std::string& channel_name)
{
	std::map<std::string, Channel>::iterator it = channels.find(channel_name);
	if (it != channels.end())
		return &(it->second);
	return NULL;
}

Channel* Server::createChannel(const std::string& channel_name)
{
	Channel* existing = getChannel(channel_name);
	if (existing)
		return existing;
	
	channels[channel_name] = Channel(channel_name);
	std::cout << "Channel " << channel_name << " created" << std::endl;
	return &channels[channel_name];
}

void	Server::removeChannel(const std::string& channel_name)
{
	Channel* ch = getChannel(channel_name);
	if (ch && ch->getMembers().size() == 0) {
		channels.erase(channel_name);
		std::cout << "Channel " << channel_name << " removed (empty)" << std::endl;
	}
}

void	Server::enablePollout(int fd) {
	for (size_t i = 0; i < fds.size(); ++i) {
		if (fds[i].fd == fd) {
			fds[i].events |= POLLOUT;
			break;
		}
	}
}

void	Server::sendToClient(int fd, const std::string& message)
{
	Client* client = getClientByFd(fd);
	if (!client)
		return ;
	client->appendWriteBuffer(message);
	enablePollout(fd);
}

void	Server::broadcastToChannel(const std::string& channel_name, const std::string& message, int except_fd)
{
	Channel* ch = getChannel(channel_name);
	if (!ch)
		return ;
	const std::set<int>& members = ch->getMembers();
	for (std::set<int>::iterator it = members.begin(); it != members.end(); ++it) {
		if (*it != except_fd) {
			Client& client = clients[*it];
			client.appendWriteBuffer(message);
			enablePollout(*it);
		}
	}
}

Client* Server::getClientByFd(int fd)
{
	std::map<int, Client>::iterator it = clients.find(fd);
	if (it != clients.end())
		return &(it->second);
	return NULL;
}

Client* Server::getClientByNickname(const std::string& nickname)
{
	std::map<std::string, int>::iterator it = nicknames.find(nickname);
	if (it != nicknames.end()) {
		int fd = it->second;
		return getClientByFd(fd);
	}
	return NULL;
}

void	Server::closeClient(size_t index)
{
	int client_fd = fds[index].fd;
	Client& client = clients[client_fd];

	if (!client.getNickname().empty())
		nicknames.erase(client.getNickname());
	
	close(client_fd);
	clients.erase(client_fd);
	fds.erase(fds.begin() + index);

	std::cout << "Client fd " << client_fd << " closed" << std::endl;
}


bool	Server::initialize()
{
	listener = getListenerSocket();
	if (listener == -1) {
		std::cerr << "Failed to create listener socket" << std::endl;
		return false;
	}

	if (makeSocketNonblocking(listener) == -1) {
		close(listener);
		return false;
	}

	pollfd server_pollfd;
	server_pollfd.fd = listener;
	server_pollfd.events = POLLIN;
	server_pollfd.revents = 0;
	fds.push_back(server_pollfd);
	
	std::cout << "Server listening on port " << port << std::endl;
	return true;
}

void	Server::run()
{
	while (true) {
		std::cout << "Wating for events... (monitoring " << fds.size() << " fds)" << std::endl;

		int poll_count = poll(&fds[0], fds.size(), -1);
		if (poll_count < 0) {
			std::cerr << "poll: " << strerror(errno) << std::endl;
			break;
		}

		std::cout << "Events detected on " << poll_count << " fd(s)" << std::endl;

		for (size_t i = 0, found = 0; i < fds.size() && found < (size_t)poll_count; ++i) {
			if (fds[i].revents == 0)
				continue;
			found++;

			if (fds[i].fd == listener) {
				handleNewConnection();
			} else {
				bool exists = handleClientEvent(i);
				if (!exists)
					--i;
			}
		}
	}
}

const std::string& Server::getPassword() const
{
	return password;
}

