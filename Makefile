build:
	docker build -t myoung34/docker-octobot:latest -t dockeroctobot_bot:latest .
	docker build -t myoung34/docker-octobot:armv6l -t dockeroctobot_bot:armv6l -f Dockerfile.armv6l .

release:
	docker push myoung34/docker-octobot:latest
	docker push myoung34/docker-octobot:armv6l

run: SHELL:=/bin/bash
run: build
	[[ ! -e .env ]] && touch .env || :
	docker-compose up
