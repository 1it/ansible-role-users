# Docker-Based Testing

Run the role against official Linux containers without `--privileged` using `community.docker.docker` or `docker compose`.

## Quick Start (Docker Compose)

```bash
./run-tests-docker.sh
```

## Multi-OS Convergence & Idempotency Matrix

Test across official Debian, Ubuntu, and Rocky Linux images (see `AGENTS.md` for the full verification harness):

- `debian:12`
- `debian:13`
- `ubuntu:24.04`
- `ubuntu:26.04`
- `rockylinux/rockylinux:9`
- `rockylinux/rockylinux:10`

All test containers are prefixed with `ansible-users-test-*` and cleaned up on exit.
