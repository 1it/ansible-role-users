# Users Role for Ansible
=========

This role allows simple management of user accounts on a system.

Requirements
------------
* Ansible 2.3.0 or higher
* Ubuntu 12.04 or higher
* Debian Wheezy or higher

## Variables

The variables that can be passed to this role and a brief description about
them are as follows:

```yaml
# The list of user accounts to be added to the system
users_current: []

# The list of user accounts to be removed from the system
users_retired: []

# The list of users keys to manage ssh authorized_keys only (e.g. for root)
users_keys: []

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
```

### User List Structure

```yaml
# The list of user accounts to be added to the system
users_current:
  # First user defining only required attributes
  - username: 'johndoe'   # Linux username
    uid: 1000             # OPTIONAL User ID (generally non-system users start at 1000)
    authorized: []        # List of public SSH keys to add to the account
  # Second user defining all available attributes
  - username: 'janedoe'   # Linux username
    uid: 1001             # OPTIONAL User ID (generally non-system users start at 1000)
    authorized:           # List of public SSH keys to add to the account
      - 'ssh-rsa key_string1'
      - 'ssh-ecdsa key_string2'
    name: 'Jane Doe'      # Used as comment when creating the account
    system: false         # Specify whether the account with be a system user
    group: 'jdoe'         # Alternate user-specific primary group
    groups:               # Additional user groups
      - 'admin'
      - 'developers'
    shell: '/bin/bash'    # Default shell for the account
    home: '/home/jdoe'    # Alternate home directory location for the account
    generate_key: true    # Generate a new SSH key for the account

# The list of user accounts to be removed from the system
users_retired:
  - username: 'johndoe'   # Linux username
    uid: 1000             # OPTIONAL User ID (not required, but useful for reference)
  - username: 'janedoe'
    uid: 1001
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
            users_current:
              - username: 'sa'
                authorized: ['ssh-rsa key_string']
                name: 'System Administrator'
                groups: ['admin']
              - username: 'ansible'
                name: 'Ansible service account'
                generate_key: true
                authorized: []
          }
    ```

__Note__: When creating a variable containing the list of users to add or remove,
the best place to start is in `group_vars/all`. Try `group_vars/groupname` or
`host_vars/hostname` if you only want users on certain machines.

## Dependencies

## License

MIT.
