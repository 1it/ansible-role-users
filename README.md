# Users Role for Ansible

This role allows simple management of user accounts on a system.

## Requirements

This role requires [Ansible](http://www.ansibleworks.com/) version 1.4 or higher and the Debian/Ubuntu platform.

## Role Variables

The variables that can be passed to this role and a brief description about
them are as follows:

```yaml
# The list of user accounts to be added to the system
users_current: []

# The list of user accounts to be removed from the system
users_retired: []

# The default shell given to all user accounts
users_default_shell: '/bin/zsh'

# The default group new user accounts will be added to
users_default_group: 'users'

# The default flag for whether to create a unique group per user or instead put
# all users in the default group defined above
users_create_group_per_user: true

# The default flag for whether to create user home directories
users_create_homedir: true

# The default flag for whether to generate passwords for new accounts. The
# randomly generated passwords are stored in the root user's home directory or 
# optionally sent to HipChat
users_create_password: false

# The HipChat API token used for new password notifications (optional)
users_hipchat_token: false

# The HipChat room used for new password notifications (optional)
users_hipchat_room: false
```

### User List Structure

```yaml
# The list of user accounts to be added to the system
users_current:
  # First user defining only required attributes
  - username: 'johndoe'   # Linux username
    uid: 1000             # User ID (generally non-system users start at 1000)
    authorized: []        # List of public SSH keys to add to the account
  # Second user defining all available attributes
  - username: 'janedoe'   # Linux username
    uid: 1001             # User ID (generally non-system users start at 1000)
    authorized:           # List of public SSH keys to add to the account
      - 'developer_key_1'
      - 'developer_key_2'
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
    uid: 1000             # User ID (not required, but useful for reference)
  - username: 'janedoe'
    uid: 1001
```

## Examples

1. Creating a system admin user and a deploy user:

    ```yaml
    ---
    # This playbook bootstraps machines with common users

    - name: Apply common users to all nodes
      hosts: all
      roles:
        - { role: users, 
            users_current:
              - username: 'sysadmin'
                uid: 1000
                authorized: ['dev_key']
                name: 'System Administrator'
                groups: ['admin']
              - username: 'deploy'
                uid: 1001
                generate_key: true
                authorized: []
          }
    ```

__Note__: When creating a variable containing the list of users to add or remove, the best place to start is in `group_vars/all`. Try `group_vars/groupname` or `host_vars/hostname` if you only want users on certain machines.

## Dependencies

None.

## License

MIT.
