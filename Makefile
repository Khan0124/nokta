.PHONY: migrate test backend-test

migrate:
@echo "Running database migrations..."
@node backend/migrations/run.js

backend-test:
npm --prefix backend test

test: backend-test
