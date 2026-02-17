# Ansible Configuration

This directory contains Ansible configuration for managing the homelab infrastructure.

## Structure

```
ansible/
├── ansible.cfg          # Main Ansible configuration
├── inventory            # Inventory file with host definitions
├── ssh.cfg             # SSH configuration for Ansible connections
├── playbooks/          # Ansible playbooks
│   └── roles/          # Ansible roles
└── README.md           # This file
```

## Inventory

The inventory includes the following groups:

- **[all_nucs]**: All NUC machines (parent group)
  - dc0, dc1, nubuntu0
- **[dcs]**: Data center servers
  - dc0, dc1
- **[workstations]**: Workstation machines
  - nubuntu0

## SSH Key Setup

### Initial Setup

1. **Generate the Ansible SSH key** (if not already created):
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_rsa -C "ansible@homelab"
   ```

2. **Store the passphrase in macOS Passwords app**:
   - Open Passwords app
   - Create new password entry named: `ansible-private-key`
   - Store the passphrase you used when creating the key

3. **Add the key to ssh-agent with Keychain integration**:
   ```bash
   ssh-add --apple-use-keychain ~/.ssh/ansible_rsa
   ```
   This will prompt for the passphrase and store it in the macOS Keychain.

4. **Copy the public key to target hosts**:
   ```bash
   ssh-copy-id -i ~/.ssh/ansible_rsa.pub ansible@dc0.local
   ssh-copy-id -i ~/.ssh/ansible_rsa.pub ansible@dc1.local
   ssh-copy-id -i ~/.ssh/ansible_rsa.pub ansible@nubuntu0.local
   ```

### Retrieving the Passphrase from Keychain

If you need to retrieve the passphrase programmatically:
```bash
security find-generic-password -a ansible-private-key -w
```

## Usage

### Test connectivity
```bash
ansible all_nucs -m ping
```

### Run ad-hoc commands
```bash
ansible dcs -m shell -a "uptime"
ansible workstations -m setup -a "filter=ansible_distribution*"
```

### Run playbooks
```bash
ansible-playbook playbooks/test-connectivity.yml
```

### Check inventory
```bash
ansible-inventory --list
ansible-inventory --graph
```

## Configuration Highlights

### ansible.cfg
- Uses custom SSH config from `./ssh.cfg`
- Default remote user: `ansible`
- Fact caching enabled for performance
- YAML output format for better readability
- Logging enabled to `./ansible.log`
- Pipelining enabled for faster execution

### ssh.cfg
- Uses `~/.ssh/ansible_rsa` private key
- Integrated with macOS Keychain via `UseKeychain yes`
- Connection multiplexing for performance
- Host key checking disabled (lab environment)
- 10-minute persistent connections

## Security Notes

⚠️ **Lab Environment Settings**:
- Host key checking is disabled
- StrictHostKeyChecking is set to `no`
- These settings are appropriate for lab/development environments
- **For production**, enable strict host key checking and maintain known_hosts

## Troubleshooting

### SSH connection issues
```bash
# Test SSH connection manually
ssh -F ./ssh.cfg dc0

# Verbose SSH debugging
ssh -F ./ssh.cfg -vvv dc0

# Check if key is loaded in ssh-agent
ssh-add -l
```

### Ansible debugging
```bash
# Increase verbosity
ansible all_nucs -m ping -vvv

# Check which config file is being used
ansible --version
```

### Clear SSH control sockets
```bash
rm -f /tmp/ansible-ssh-*
```

## Best Practices

1. **Use group_vars and host_vars** for variable management
2. **Create roles** for reusable configurations
3. **Use ansible-vault** for sensitive data
4. **Test with `--check --diff`** before applying changes
5. **Tag your plays** for selective execution
6. **Document your playbooks** with comments and README files
