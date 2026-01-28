#include "Server.hpp"
#include <iostream>

// ./ircserv <port> <password>
int main(int argc, char **argv) {

	if (argc != 3) {
		std::cerr << "Usage: ./ircserv <port> <password>" << std::endl;
		return 1;
	}

	const char* port = argv[1];
	const char* password = argv[2];

	Server server(port, password);
	if (!server.initialize()) {
		std::cerr << "Failed to initialize server" << std::endl;
		return 1;
	}

	server.run();

	return 0;
}
