#!/usr/bin/env bash
set -euo pipefail

cleanup() {
  docker compose down --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker compose build
docker compose up -d

docker compose exec -T ansible-test ansible-playbook -i tests/inventory tests/users.yml
docker compose exec -T ansible-test ansible-playbook -i tests/inventory tests/test_comprehensive_groups.yml
docker compose exec -T ansible-test ansible-playbook -i tests/inventory tests/test_empty_group_list.yml
