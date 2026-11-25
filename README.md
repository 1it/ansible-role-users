# Ansible Role: Users (`1it.users`)

Modern, production-ready Ansible role for declaratively managing Linux user accounts, primary and supplementary groups, SSH keys and `.ssh` permissions, validated `/etc/sudoers.d/` drop-ins, `/etc/security/limits.d/` PAM resource limits, and systemd user lingering.

## Requirements

- **Ansible:** `>= 2.12` (tested on `ansible-core 2.22`)
- **Supported OSes (`amd64` & `arm64`):**
  - Debian 12 (Bookworm), Debian 13 (Trixie)
  - Ubuntu 24.04 (Noble), Ubuntu 26.04 (Resolute)
  - Enterprise Linux 8, 9, 10 (RHEL, Rocky Linux, AlmaLinux, CentOS Stream)
- **Collections:**
  - `ansible.posix` (`>= 1.5.0`)

Install collection dependencies:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Features & Production Hygiene

- **FQCNs & modern Ansible:** Uses `ansible.builtin.*` and `ansible.posix.*` throughout, `ansible_facts['...']` instead of legacy top-level facts, native Jinja2 types safe on Ansible 2.19+, and full `meta/argument_specs.yml` input validation.
- **Host targeting without crashes:** Safely evaluates `target_hosts` against `all`, `inventory_hostname`, and `group_names` without failing on undefined inventory groups or running duplicate tasks when a host belongs to multiple matching groups.
- **Additive override lists:** Extend `users`, `users_group_list`, and `users_limits` via `users_extra`, `users_extra_groups`, and `users_extra_limits` with automatic deduplication.
- **Safe defaults:**
  - Dedicated per-user primary groups (`users_create_group_per_user: true`).
  - Home directory mode `0750` without dangerous recursive `chown` (`users_homedir_recurse: false`).
  - System accounts (`system: true`) default to `/usr/sbin/nologin` and skip home directory creation unless `home`, `create_home`, `generate_key`, or `authorized` is set.
  - `ed25519` default key type when `generate_key: true`.
  - Automatic `no_log` protection whenever any user sets `password` (`users_no_log: true`).
  - Home directory removal on `state: absent` is opt-in (`users_delete_homedirs: false`) and guarded against protected system paths (`users_protected_home_paths`).
- **Drop-in configuration:**
  - Per-user `/etc/sudoers.d/90-ansible-user-<name>` drop-ins validated with `visudo -cf %s` (with dot-safe filenames so `sudo` never silently ignores usernames containing `.`).
  - Per-user and global `/etc/security/limits.d/90-ansible-users.conf` PAM resource limits.
  - Optional `loginctl enable-linger` / `disable-linger` for rootless containers and user systemd services.

## Tags

| Tag | Scope |
|-----|-------|
| `always` | Input validation, OS variable loading, host target resolution |
| `users` | Full role execution |
| `users_prerequisites` | Conditional installation of `openssh-client(s)` / `sudo` when required |
| `users_groups`, `groups` | Default, additional, and per-user primary group creation |
| `users_accounts`, `accounts` | User creation/updates, home directory permissions, account removal |
| `users_ssh`, `ssh` | `.ssh` directory security, `authorized_keys` deployment/revocation |
| `users_sudoers`, `sudoers` | `/etc/sudoers.d/` drop-in management |
| `users_limits`, `limits` | `/etc/security/limits.d/` PAM resource limits |
| `users_linger`, `linger` | Systemd user lingering (`loginctl`) |
| `users_cleanup`, `cleanup` | Removal of absent groups, drop-ins, linger files, and optional home dirs |
| `security` | SSH, home directory permissions, sudoers, and limits tasks |
| `directories` | Home directory permission and cleanup tasks |

## Key Defaults

See `defaults/main.yml` and `meta/argument_specs.yml` for the complete schema.

| Variable | Default | Description |
|----------|---------|-------------|
| `users` | `[]` | Primary list of user account definitions |
| `users_extra` | `[]` | Additive user entries merged onto `users` |
| `users_group_list` | `[]` | Primary list of additional groups (`name`, `state`, `gid`, `system`) |
| `users_extra_groups` | `[]` | Additive group entries merged onto `users_group_list` |
| `users_default_target_hosts` | `['all']` | Default `target_hosts` when omitted on a user entry |
| `users_default_shell` | `/bin/bash` | Default shell for regular users |
| `users_default_system_shell` | `/usr/sbin/nologin` | Default shell for `system: true` users |
| `users_default_group` | `users` | Primary group when `users_create_group_per_user: false` |
| `users_create_group_per_user` | `true` | Create dedicated primary group per user |
| `users_create_homedir` | `true` | Create home directories for regular users |
| `users_home_base` | `/home` | Parent directory for default user home paths |
| `users_home_mode` | `"0750"` | Permissions mode on managed home directories |
| `users_homedir_recurse` | `false` | Recursively chown home directories (opt-in) |
| `users_groups_append` | `false` | Append supplementary groups instead of replacing |
| `users_default_ssh_key_type` | `ed25519` | Default SSH key type for `generate_key: true` |
| `users_default_ssh_exclusive` | `false` | Default `exclusive` mode for `authorized_keys` |
| `users_no_log` | `true` | Enable `no_log` when any user defines `password` |
| `users_sudoers_dir` | `/etc/sudoers.d` | Drop-in directory for per-user sudo rules |
| `users_limits_file` | `/etc/security/limits.d/90-ansible-users.conf` | Managed PAM limits drop-in file |
| `users_limits` / `users_extra_limits` | `[]` | Global and additive PAM resource limits |
| `users_manage_prerequisites` | `true` | Install missing `openssh-client(s)` / `sudo` only when required |
| `users_delete_homedirs` | `false` | Delete home dirs on `state: absent` (destructive, opt-in; legacy alias `delete_homedirs` still supported) |

## Example Playbook

```yaml
---
- name: Configure Linux users, groups, SSH keys, sudoers, and limits
  hosts: all
  become: true

  roles:
    - role: 1it.users
      vars:
        users_group_list:
          - name: developers
            gid: 2100
            state: present
          - name: ops
            state: present

        users_limits:
          - domain: "@developers"
            type: soft
            item: nofile
            value: "65536"
          - domain: "@developers"
            type: hard
            item: nofile
            value: "131072"

        users:
          - username: alice
            name: Alice Admin
            uid: 2001
            groups:
              - ops
            authorized:
              - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... alice@workstation"
            exclusive: true
            generate_key: true
            sudo:
              nopasswd: true
              commands:
                - /usr/bin/systemctl status *
                - /usr/bin/journalctl *
            target_hosts:
              - all
            state: present

          - username: deploy
            name: Deployment Service Account
            system: true
            home: /opt/deploy
            shell: /bin/bash
            generate_key: true
            linger: true
            limits:
              - type: "-"
                item: nproc
                value: "32768"
            target_hosts:
              - production
            state: present

          - username: former_user
            target_hosts:
              - all
            state: absent
```

## License

[MIT](LICENSE)
