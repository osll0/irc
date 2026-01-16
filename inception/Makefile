DATA_DIR = /home/${USER}/data
COMPOSE_FILE = srcs/docker-compose.yml
DOMAIN_NAME = $(shell grep DOMAIN_NAME srcs/.env | cut -d '=' -f2)

all: setup up

setup:
	@echo "Creating data directories..."
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	@echo "Data directories created!"
	@grep -q "$(DOMAIN_NAME)" /etc/hosts || echo "127.0.0.1 $(DOMAIN_NAME)" | sudo tee -a /etc/hosts > /dev/null

up: setup
	@docker compose -f $(COMPOSE_FILE) up -d --build

down:
	@docker compose -f $(COMPOSE_FILE) down

clean: down
	@docker compose -f $(COMPOSE_FILE) down -v
	@echo "Removing data directories..."
	@sudo rm -rf $(DATA_DIR)
	@sudo sed -i "/$(DOMAIN_NAME)/d" /etc/hosts 2>/dev/null || true
	@echo "Clean complete!"

re: clean all

.PHONY: all setup up down clean re
