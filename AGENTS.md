# AGENTS.md — `ansible-role-users`

Role-specific conventions, platform guardrails, and validation commands for maintaining `ansible-role-users`.

## Role Conventions

- **Ansible compatibility:** Target `ansible-core >= 2.12` through latest (`2.19–2.22+`).
- **FQCNs only:** Always use `ansible.builtin.*` and `ansible.posix.*` module names (never short names). Keep runtime collection dependencies limited to `ansible.posix`.
- **Facts access:** Always use `ansible_facts['...']` (`os_family`, `distribution`, `distribution_major_version`, `hostname`, `system`, `python`); never use legacy top-level `ansible_*` variables.
- **Native Jinja2 types (Ansible ≥2.19):** Never mix `{% set %}` / `{% for %}` statements with `{{ ... }}` inside `set_fact` when producing lists or dicts. Use single `{{ ... }}` expressions with task-level `vars:` or clean `loop:` tasks.
- **Explicit permissions:** Every `file` and `template` task must specify `owner`, `group`, and quoted octal `mode` (e.g., `"0750"`, `"0700"`, `"0600"`, `"0440"`, `"0644"`). Never pass `mode:` on a task with `recurse: true`.
- **Task naming & layout:** Prefix all task names with `Section | Description` matching the task file (`Prepare |`, `Prerequisites |`, `Groups |`, `Accounts |`, `SSH |`, `Sudoers |`, `Limits |`, `Linger |`, `Cleanup |`). Statically import task files from `tasks/main.yml` using `ansible.builtin.import_tasks`.
- **Metadata sync:** Whenever variables or behavior change, update `defaults/main.yml`, `meta/argument_specs.yml`, `meta/main.yml`, and `README.md` together.

## Platform Guardrails

- **Supported OS matrix (`amd64` + `arm64`):** Debian 12/13, Ubuntu 24.04/26.04, EL 8/9/10 (RHEL, Rocky, AlmaLinux, CentOS Stream). Do not add legacy EL 7, Debian ≤11, Ubuntu ≤20.04, or macOS workarounds.
- **Sudoers drop-in filenames:** `sudo` silently ignores files in `/etc/sudoers.d/` containing `.` or ending in `~`. Always encode usernames collision-free (`replace('_', '__') | replace('.', '_dot_')`) and always validate templates with `visudo -cf %s`.
- **Protected paths:** Never chown, chmod, recurse, or delete paths listed in `users_protected_home_paths` (always reject `.` / `..` path segments and collapse repeated/trailing slashes via `regex_replace` so both Ansible 2.12+ compatibility and `//opt` canonicalization hold).
- **Minimal container/server prerequisites:** Do not install packages unconditionally. Only check/install `openssh-client(s)` or `sudo` when configured users actually request `generate_key: true` or `sudo` and the binary is missing. On minimal Debian/Ubuntu hosts, check/bootstrap `python3-apt` before calling `ansible.builtin.apt`.
- **Systemd lingering:** Only invoke `loginctl` when `/run/systemd/system` exists so non-systemd containers stay idempotent and error-free.
- **Sensitive data:** Keep `users_no_log: true` by default so `password` hashes are not exposed in task output.

## Validation & Testing Commands

### 1. Syntax & Argument Spec Check

```bash
tmp_pb="$(mktemp /tmp/users-syntax-XXXXXX.yml)"
trap 'rm -f "${tmp_pb}"' EXIT
cat > "${tmp_pb}" <<'EOF'
---
- name: Syntax check
  hosts: localhost
  gather_facts: false
  roles:
    - role: .
EOF
ansible-playbook --syntax-check -i localhost, "${tmp_pb}"
```

### 2. Template Rendering Check (`jinja2.StrictUndefined`)

```bash
python3 - <<'PY'
from jinja2 import Environment, FileSystemLoader, StrictUndefined
from ansible.plugins.filter.core import to_bool

env = Environment(loader=FileSystemLoader("templates"), undefined=StrictUndefined)
env.filters["bool"] = to_bool

sudo_tpl = env.get_template("sudoers.j2")
for ctx in [
    {"_user": {"username": "alice"}, "_sudo_config": {}, "users_sudoers_default_nopasswd": False},
    {"_user": {"username": "jane.doe"}, "_sudo_config": {"nopasswd": True, "commands": ["/usr/bin/id", "/usr/bin/systemctl status *"], "runas": "root", "hosts": "ALL", "defaults": ["!requiretty"]}, "users_sudoers_default_nopasswd": False},
]:
    rendered = sudo_tpl.render(**ctx)
    assert ctx["_user"]["username"] in rendered

limits_tpl = env.get_template("limits.conf.j2")
rendered_limits = limits_tpl.render(_users_limits_resolved=[
    {"domain": "alice", "type": "soft", "item": "nofile", "value": "65536"},
    {"domain": "@developers", "type": "hard", "item": "nproc", "value": "32768"},
])
assert "alice soft nofile 65536" in rendered_limits
print("All templates rendered cleanly under StrictUndefined.")
PY
```

### 3. Docker Integration & Second-Run Idempotency Tests

Never use `--privileged` for unprivileged user/group/SSH/sudoers/limits tests. Prefix all test containers with `ansible-users-test-*` and always remove them via `trap ... EXIT`:

```bash
tmp_pb="$(mktemp /tmp/ansible-users-test-XXXXXX.yml)"
trap 'rm -f "${tmp_pb}"' EXIT
cat > "${tmp_pb}" <<'EOF'
---
- name: Converge users role
  hosts: all
  gather_facts: true
  vars:
    users_group_list:
      - name: developers
        state: present
    users:
      - username: alice
        uid: 2001
        groups: [developers]
        generate_key: true
        sudo:
          nopasswd: true
          commands: [/usr/bin/id]
        limits:
          - type: soft
            item: nofile
            value: "65536"
        state: present
  roles:
    - role: .
EOF

for img in debian:12 debian:13 ubuntu:24.04 ubuntu:26.04 rockylinux/rockylinux:9 rockylinux/rockylinux:10; do
  cname="ansible-users-test-$(echo "${img}" | tr '/:' '--')"
  docker rm -f "${cname}" >/dev/null 2>&1 || true
  docker run -d --name "${cname}" "${img}" sleep infinity
  # Bootstrap python3 on minimal Debian/Ubuntu images if absent
  if echo "${img}" | grep -Eq '^(debian|ubuntu):'; then
    docker exec "${cname}" sh -c 'apt-get update -qq && apt-get install -y --no-install-recommends python3 >/dev/null'
  fi
  ansible-playbook -i "${cname}," -c community.docker.docker "${tmp_pb}"
  # Second run must report changed=0
  ansible-playbook -i "${cname}," -c community.docker.docker "${tmp_pb}"
  docker rm -f "${cname}" >/dev/null 2>&1 || true
done
```
