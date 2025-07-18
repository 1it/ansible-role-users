# Docker-Based Testing

This role includes Docker-based testing to ensure comprehensive functionality testing across different Linux environments, avoiding platform-specific limitations (like macOS user management restrictions).

## Prerequisites

- Docker
- Docker Compose

## Quick Start

Run all tests with a single command:

```bash
./run-tests-docker.sh
```

This script will:
1. Build a Ubuntu 22.04 container with Ansible installed
2. Run the comprehensive user management tests
3. Execute additional functionality tests
4. Perform ansible-lint checks
5. Clean up the environment

## Manual Testing

For manual testing or debugging:

```bash
# Start the test environment
docker-compose up -d

# Enter the container
docker-compose exec ansible-test bash

# Run specific tests
ansible-playbook -i tests/inventory tests/users.yml -v
ansible-playbook -i tests/inventory tests/test_comprehensive_groups.yml -v
ansible-playbook -i tests/inventory tests/test_empty_group_list.yml -v

# Clean up
docker-compose down
```

## Test Coverage

The Docker tests cover:

- ✅ User creation with custom UIDs, shells, and home directories
- ✅ Group management and user group memberships
- ✅ SSH key management and directory security
- ✅ System user creation
- ✅ User removal/cleanup operations
- ✅ Per-user group creation
- ✅ Cross-platform compatibility validation
- ✅ Empty group handling
- ✅ Ansible best practices (linting)

## Container Details

- **Base Image**: Ubuntu 22.04 LTS
- **Ansible Version**: Latest stable
- **Required Collections**: ansible.posix, community.general
- **Privileges**: Container runs with privileged mode for user management

## Troubleshooting

### Permission Issues
The container runs in privileged mode to allow user management operations. This is required for testing user creation, deletion, and group management.

### Test Failures
If tests fail, check the detailed output for specific error messages. Common issues:
- Missing dependencies (automatically installed in container)
- Permission problems (should not occur in privileged container)
- Network connectivity (for downloading collections)

### Debugging
To debug test failures:

```bash
# Start container and keep it running
docker-compose up -d

# Enter container for manual debugging
docker-compose exec ansible-test bash

# Run tests with maximum verbosity
ansible-playbook -i tests/inventory tests/users.yml -vvv
```

## CI/CD Integration

This Docker setup can be easily integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Run Docker Tests
  run: |
    chmod +x run-tests-docker.sh
    ./run-tests-docker.sh
```

## Performance

Typical test execution times:
- Container build: ~2-3 minutes (first time)
- Test execution: ~30-60 seconds
- Total runtime: ~3-4 minutes (first run), ~1 minute (subsequent runs)