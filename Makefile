test:
	virtualenv venv
	. venv/bin/activate
	pip install -r requirements-test.txt
	pytest

build:
	docker-compose build

run: build
	docker-compose up
