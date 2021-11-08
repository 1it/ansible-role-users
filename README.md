# Users Role for Ansible

This role allows simple management of user accounts on a system.  
Since `v0.2` it's possible to control where to create a certain user account - by setting the target host group (eg. inventory group, EC2 tag or other cloud label)


# Changelog

## 0.2.1 - 2021-11-08

### Added:

Remove user group  
Remove user homedir - `delete_homedirs`

## 0.2 - 2021-11-08

### Changed:

`target_hosts` now is mandatory. Please add `target_hosts: ['all']` to each user entry if you want to create this user on all hosts.

### Removed:
`users_keys` is removed due to compability issues. Probably it was not used at all.

## 0.1 - 2021-10-27

### Fixes:

`groups` should be omited by default, other default values.

### Added:

`target_hosts` first try (not working).

### Changed:

`users.state` is mandatory.

Requirements
------------
* Ansible 2.9.0 or higher


## Variables

The variables that can be passed to this role and a brief description about
them are as follows:

```yaml
# The list of user accounts to be added to the system
users: []

# The default shell given to all user accounts
users_default_shell: '/bin/bash'

# The default group new user accounts will be added to
users_default_group: 'users'

# The default flag for whether to create a unique group per user or instead put
# all users in the default group defined above
users_create_group_per_user: true

# The default flag for whether to create user home directories
users_create_homedir: true

# The default groups list (to be created)
users_group_list: []

# Delete homedirs on user removal - disabled by default
delete_homedirs: false
```

### User List Structure

```yaml
# The list of user accounts to be added to the system
users:
  # First user defining only required attributes
  - username: 'johndoe'     # Linux username
    uid: 1000               # OPTIONAL User ID (generally non-system users start at 1000)
    authorized: []          # List of public SSH keys to add to the account
    target_hosts: ['dev']   # List of inventory host groups where user account should exist
    state: 'present'        # REQUIRED account state
  # Second user defining all available attributes
  - username: 'janedoe'     # Linux username
    uid: 1001               # OPTIONAL User ID (generally non-system users start at 1000)
    authorized:             # List of public SSH keys to add to the account
      - 'ssh-rsa key_string1'
      - 'ssh-ecdsa key_string2'
    name: 'Jane Doe'        # Used as comment when creating the account
    system: false           # Specify whether the account with be a system user
    group: 'jdoe'           # Alternate user-specific primary group
    groups:                 # Additional user groups
      - 'admin'
      - 'developers'
    shell: '/bin/bash'      # Default shell for the account
    home: '/home/jdoe'      # Alternate home directory location for the account
    generate_key: true      # Generate a new SSH key for the account
    state: 'present'
  # Decommissioned accounts
  - username: 'bob'
    uid: 1003
    authorized: []
    target_hosts: ['dev']
    state: absent

```

## Playbook example

1. Creating a system admin user and a deploy user:

    ```yaml
    ---
    # This playbook bootstraps machines with common users

    - name: Apply common users to all nodes
      hosts: all
      roles:
        - { role: users,
            users:
              - username: 'sa'
                authorized: ['ssh-rsa key_string']
                name: 'System Administrator'
                groups: ['admin']
                target_hosts:
                  - dev
                  - stage
                  - prod
                state: 'present'
              - username: 'ansible'
                name: 'Ansible service account'
                generate_key: true
                authorized: []
                state: 'present'
                # Caveat - target_hosts must be defined otherwise user will not be created.
                # Use ['all'] to create a user on all hosts by default.
                target_hosts: ['all']
              - username: 'johndoe'
                name: 'John Doe'
                generate_key: true
                authorized: []
                target_hosts: ['dev']
                state: 'present'
          }
    ```

__Note__: When creating a variable containing the list of users to add or remove,
the best place to start is in `group_vars/all`. Try `group_vars/groupname` or
`host_vars/hostname` if you only want users on certain machines.
`target_hosts` is a list host groups also it could be a Tag in a dynamic cloud inventory, like AWS/GCP/WhateverCloud, availability zone, region, project.

## Dependencies

## License

MIT.
