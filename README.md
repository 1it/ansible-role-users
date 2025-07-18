# Ansible Role: Users

[![CI](https://github.com/1it/ansible-role-users/workflows/CI/badge.svg)](https://github.com/1it/ansible-role-users/actions)
[![Ansible Galaxy](https://img.shields.io/badge/ansible--galaxy-1it.users-blue.svg)](https://galaxy.ansible.com/1it/users)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A modern, cross-platform Ansible role for managing user accounts, SSH keys, and groups with fine-grained control over target hosts.

## Features

- ✅ **Cross-platform support**: Linux distributions (Ubuntu, Debian, RHEL, CentOS, Fedora, openSUSE, Arch)
- ✅ **Flexible user management**: Create, modify, and remove users with full control
- ✅ **SSH key management**: Automated SSH key deployment and management
- ✅ **Group management**: Create and manage user groups
- ✅ **Target host control**: Deploy users to specific host groups or inventory tags
- ✅ **Security-focused**: Per-user groups, proper permissions, secure defaults
- ✅ **Comprehensive testing**: Molecule tests with multiple platforms
- ✅ **Idempotent operations**: Safe to run multiple times


## Requirements

- **Ansible**: >= 2.12.0
- **Python**: >= 3.8
- **Target OS**: Linux distributions (see supported platforms in meta/main.yml)
- **Collections**:
  - `community.general` >= 6.0.0
  - `ansible.posix` >= 1.4.0

## Installation

### From Ansible Galaxy

```bash
ansible-galaxy install 1it.users
```

### From GitHub

```bash
ansible-galaxy install git+https://github.com/1it/ansible-role-users.git
```

### Using requirements.yml

Create a `requirements.yml` file:

```yaml
---
roles:
  - name: 1it.users
    version: main

collections:
  - community.general
  - ansible.posix
```

Then install:

```bash
ansible-galaxy install -r requirements.yml
```


## Role Variables

### Core Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `users` | `[]` | List of users to manage (see structure below) |
| `users_group_list` | `[]` | List of groups to create/manage |
| `users_default_shell` | `/bin/bash` | Default shell for new users |
| `users_default_group` | `users` | Default primary group (when not using per-user groups) |
| `users_create_group_per_user` | `true` | Create unique group per user (recommended) |
| `users_create_homedir` | `true` | Create home directories for users |
| `delete_homedirs` | `false` | Remove home directories when deleting users ⚠️ |

### Security Considerations

- **Per-user groups**: Enabled by default for better security isolation
- **Home directory permissions**: Automatically set to 0700 for SSH directories
- **SSH key management**: Supports exclusive key management
- **Privilege escalation**: Role requires `become: true` for user management

### User Configuration Structure

#### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `username` | string | Linux username (must be valid) |
| `target_hosts` | list | Host groups where user should exist |
| `state` | string | `present` or `absent` |

#### Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `uid` | integer | auto | User ID (typically 1000+) |
| `name` | string | `""` | Full name (GECOS field) |
| `authorized` | list | `[]` | SSH public keys |
| `groups` | list | `[]` | Additional groups |
| `shell` | string | `users_default_shell` | Login shell |
| `home` | string | `/home/{username}` | Home directory path |
| `system` | boolean | `false` | Create as system user |
| `generate_key` | boolean | `false` | Generate SSH key pair |
| `exclusive` | boolean | `false` | Remove unlisted SSH keys |
| `password` | string | `null` | Encrypted password hash |

#### Example Configuration

```yaml
users:
  # Minimal user configuration
  - username: 'developer'
    target_hosts: ['webservers']
    state: 'present'
    
  # Full-featured user
  - username: 'admin'
    uid: 1001
    name: 'System Administrator'
    authorized:
      - 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... admin@workstation'
      - 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... admin@laptop'
    groups:
      - 'sudo'
      - 'docker'
    shell: '/bin/zsh'
    generate_key: true
    exclusive: true
    target_hosts: ['all']
    state: 'present'
    
  # Remove user
  - username: 'olduser'
    target_hosts: ['all']
    state: 'absent'
```

### Group Configuration Structure

```yaml
users_group_list:
  - name: 'developers'
    state: 'present'  # default
  - name: 'docker'
    state: 'present'
  - name: 'temporary'
    state: 'absent'   # remove group
```

**Note**: Group creation is automatically skipped on macOS due to platform limitations.

## Usage Examples

### Basic Playbook

```yaml
---
- name: Manage users across infrastructure
  hosts: all
  become: true
  
  roles:
    - role: 1it.users
      vars:
        users_group_list:
          - name: 'developers'
          - name: 'sysadmins'
          - name: 'docker'
        
        users:
          - username: 'admin'
            name: 'System Administrator'
            authorized:
              - 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... admin@workstation'
            groups: ['sudo', 'sysadmins']
            target_hosts: ['all']
            state: 'present'
            
          - username: 'developer'
            name: 'Development User'
            groups: ['developers', 'docker']
            target_hosts: ['webservers', 'appservers']
            state: 'present'
```

### Advanced Configuration

```yaml
---
- name: Advanced user management
  hosts: all
  become: true
  
  vars:
    # Global role configuration
    users_create_group_per_user: true
    users_default_shell: '/bin/zsh'
    delete_homedirs: false
    
  roles:
    - role: 1it.users
      vars:
        users:
          # Service account with generated SSH key
          - username: 'deploy'
            name: 'Deployment Service Account'
            system: true
            generate_key: true
            home: '/opt/deploy'
            shell: '/bin/bash'
            target_hosts: ['production']
            state: 'present'
            
          # Developer with multiple SSH keys
          - username: 'jane.doe'
            name: 'Jane Doe'
            authorized:
              - 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... jane@laptop'
              - 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... jane@desktop'
            exclusive: true  # Remove any other keys
            groups: ['developers', 'sudo']
            target_hosts: ['development', 'staging']
            state: 'present'
```

### Environment-Specific Users

```yaml
# group_vars/production.yml
users:
  - username: 'prod-admin'
    name: 'Production Administrator'
    groups: ['sudo']
    target_hosts: ['all']
    state: 'present'

# group_vars/development.yml  
users:
  - username: 'dev-user'
    name: 'Development User'
    groups: ['developers']
    target_hosts: ['all']
    state: 'present'
```

### Best Practices

- **Variable placement**: Use `group_vars/all` for common users, `group_vars/{environment}` for environment-specific users
- **Target hosts**: Can be inventory groups, cloud tags, or any dynamic inventory labels
- **SSH keys**: Store in encrypted files or use Ansible Vault for sensitive keys
- **Testing**: Always test user changes in non-production environments first

## Testing

This role includes comprehensive testing using [Molecule](https://molecule.readthedocs.io/).

### Prerequisites

```bash
pip install molecule[docker] ansible-core
```

### Running Tests

```bash
# Test all scenarios
molecule test

# Test specific platform
molecule test --scenario-name default

# Development workflow
molecule converge  # Apply role
molecule verify    # Run tests
molecule destroy   # Clean up
```

### Manual Testing

The role includes custom tests for the empty group bug fix:

```bash
# Run the comprehensive test suite
ansible-playbook -i tests/inventory tests/test_comprehensive_groups.yml

# Run the empty group specific test
./tests/run_empty_group_test.sh
```

## Development

### Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Run tests: `molecule test`
5. Commit changes: `git commit -m 'Add amazing feature'`
6. Push to branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Code Style

- Follow [Ansible best practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- Use YAML lint: `yamllint .`
- Test with multiple platforms
- Document all variables and examples

## Changelog

### v1.0.0 (2024)

#### Added
- ✅ Modern Ansible support (2.12+)
- ✅ Cross-platform compatibility
- ✅ Comprehensive Molecule testing
- ✅ macOS compatibility (with limitations)
- ✅ Enhanced documentation
- ✅ CI/CD pipeline

#### Fixed
- 🐛 Empty group creation bug (`[]` group)
- 🐛 Loop syntax issues
- 🐛 Platform-specific group management

#### Changed
- 🔄 Updated minimum Ansible version to 2.12.0
- 🔄 Modernized role structure
- 🔄 Improved variable documentation
- 🔄 Enhanced security defaults

#### Removed
- ❌ Deprecated `users_keys` variable
- ❌ Support for EOL distributions

### Legacy Versions

<details>
<summary>Click to expand legacy changelog</summary>

#### v0.2.1 (2021-11-08)
- Added user group removal
- Added `delete_homedirs` option

#### v0.2 (2021-11-08)
- Made `target_hosts` mandatory
- Removed `users_keys` for compatibility

#### v0.1 (2021-10-27)
- Initial release
- Basic user and group management

</details>

## Dependencies

No external role dependencies. See [Requirements](#requirements) for collection dependencies.

## License

[MIT](LICENSE)

## Author Information

This role was created by [Ivan Tuzhilkin](https://github.com/1it) and is maintained by the community.

---

**Support**: For issues and questions, please use the [GitHub Issues](https://github.com/1it/ansible-role-users/issues) page.
