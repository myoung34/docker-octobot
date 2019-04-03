build:
	docker build -t myoung34/docker-octobot:latest -t dockeroctobot_bot:latest .

release:
	docker push myoung34/docker-octobot:latest

run: SHELL:=/bin/bash
run: build
	[[ ! -e .env ]] && touch .env || :
	docker-compose up
