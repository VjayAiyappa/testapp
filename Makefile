# ------------------------------------------------------------------------------
# IMPORTANT NOTE:
# This file requires tabs to work properly, do not substitute them with spaces.
# ------------------------------------------------------------------------------

SHELL := /bin/bash


prepare:
	./_scripts/secrets.sh && \
	docker-compose pull db nginx smtp redis

build: build-backend build-frontend build-mobile

serve: serve-backend serve-frontend serve-mobile

lint:
	pre-commit run --all-files

test: test-backend test-frontend test-mobile

docs: docs-backend docs-frontend docs-mobile

check-deps: check-deps-backend check-deps-frontend check-deps-mobile

purge: purge-backend purge-frontend purge-mobile

down:
	docker-compose down


# ------------------------------------------------------------------------------
# Backend
# ------------------------------------------------------------------------------

init-backend: purge-backend build-backend

build-backend:
	docker-compose build backend

serve-backend:
	docker-compose up backend

test-backend:
	docker-compose up -d db && \
	docker-compose run --rm --no-deps backend test

docs-backend:
	docker-compose run --rm --no-deps backend gen_docs

shell-backend:
	docker-compose run --rm --no-deps backend sh

py-shell-backend:
	docker-compose run --rm --no-deps backend manage shell

db-shell-backend:
	docker-compose up -d db && \
	docker-compose run --rm --no-deps backend manage dbshell

db-prepare-backend:
	docker-compose up -d db && \
	docker-compose run --rm --no-deps backend manage makemigrations

db-migrate-backend:
	docker-compose up -d db && \
	docker-compose run --rm --no-deps backend manage migrate

check-deps-backend:
	docker-compose run --rm --no-deps backend eval pip list --outdated

purge-backend:
	docker-compose down -v


# ------------------------------------------------------------------------------
# Frontend (with node)
# ------------------------------------------------------------------------------

init-frontend: purge-frontend build-frontend

build-frontend:
	pushd frontend && \
	npm install && \
	popd

serve-frontend:
	pushd frontend && \
	npm run start-dev

test-frontend:
	pushd frontend && \
	CI=true npm run test && \
	popd

docs-frontend:
	pushd frontend && \
	npm run docs && \
	popd

check-deps-frontend:
	pushd frontend && \
	npm outdated || true && \
	popd

purge-frontend:
	rm -rf frontend/node_modules frontend/build frontend/docs

# ------------------------------------------------------------------------------
# Frontend (with docker)
# ------------------------------------------------------------------------------

build-frontend-docker:
	docker-compose kill frontend && \
	docker-compose rm -f frontend && \
	docker volume rm biskit_frontend_node_modules || true && \
	docker-compose build frontend

serve-frontend-docker:
	docker-compose up frontend

test-frontend-docker:
	docker-compose run --rm --no-deps frontend test

docs-frontend-docker:
	docker-compose run --rm --no-deps frontend eval npm run docs

shell-frontend-docker:
	docker-compose run --rm --no-deps frontend sh

check-deps-frontend-docker:
	docker-compose run --rm --no-deps frontend eval npm outdated || true


# ------------------------------------------------------------------------------
# Mobile
# ------------------------------------------------------------------------------

init-mobile: purge-mobile build-mobile

build-mobile:
	pushd mobile && \
	npm install && \
	popd

build-mobile-apk: build-mobile
	pushd mobile/android && \
	./gradlew assembleRelease && \
	popd

serve-mobile:
	pushd mobile && \
	npm run android && \
	npm run start

test-mobile:
	pushd mobile && \
	CI=true npm run test && \
	popd

docs-mobile:
	pushd mobile && \
	npm run docs && \
	popd

check-deps-mobile:
	pushd mobile && \
	npm outdated || true && \
	popd

purge-mobile:
	rm -rf mobile/node_modules mobile/build mobile/docs mobile/android/build mobile/android/.gradle


# ------------------------------------------------------------------------------
# Production
# ------------------------------------------------------------------------------

build-prod:
	docker-compose -f docker-compose.production.yml pull db nginx redis && \
	docker-compose -f docker-compose.production.yml build backend frontend

serve-prod:
	docker-compose -f docker-compose.production.yml up backend rq frontend

restart-prod:
	docker-compose -f docker-compose.production.yml down && \
	docker-compose -f docker-compose.production.yml up -d backend rq frontend

down-prod:
	docker-compose -f docker-compose.production.yml down

shell-prod-front:
	docker-compose -f docker-compose.production.yml run --rm --no-deps frontend sh

shell-prod-back:
	docker-compose -f docker-compose.production.yml run --rm --no-deps backend sh

py-shell-prod:
	docker-compose -f docker-compose.production.yml run --rm --no-deps backend manage shell

db-shell-prod:
	docker-compose -f docker-compose.production.yml up -d db && \
	docker-compose -f docker-compose.production.yml run --rm --no-deps backend manage dbshell

db-migrate-prod:
	docker-compose -f docker-compose.production.yml up -d db && \
	docker-compose -f docker-compose.production.yml run --rm --no-deps backend manage migrate

logs-prod:
	docker-compose -f docker-compose.production.yml logs frontend && \
	docker-compose -f docker-compose.production.yml logs backend && \
	docker-compose -f docker-compose.production.yml logs rq
