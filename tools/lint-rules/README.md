# Custom Ansible Lint Rules

This directory contains custom ansible-lint rules for enforcing organizational standards.

## Rules

### ORG001: Playbook Naming Convention

Enforces the `verb-noun.yml` naming pattern for Ansible playbooks.

**Requirements:**
- Playbooks must start with an approved verb (see `approved-ansible-verbs.yml`)
- Use lowercase only
- Use hyphens as separators (not underscores)
- Follow verb-noun pattern
- Must have `.yml` or `.yaml` extension

**Valid Examples:**
```
✓ build-image.yml
✓ deploy-application.yml
✓ configure-network.yml
✓ validate-release.yml
✓ rotate-secrets.yml
```

**Invalid Examples:**
```
✗ run-stuff.yml           # 'run' is not an approved verb
✗ BuildImage.yml          # Not lowercase
✗ deploy_app.yml          # Uses underscores instead of hyphens
✗ main.yml                # Doesn't follow verb-noun pattern
✗ do-things.yml           # 'do' is not an approved verb
```

## Approved Verbs

The source of truth for approved verbs is maintained in:
**`tools/approved-ansible-verbs.yml`**

Current approved verbs (alphabetized):
- apply, audit, bootstrap, build, cleanup, configure, create, deploy, destroy
- disable, enable, harden, initialize, install, migrate, promote, publish
- register, remove, rotate, sync, test, update, upgrade, validate, verify

## Usage

These rules are automatically loaded by ansible-lint when configured in `.ansible-lint`:

```yaml
rulesdir:
  - tools/lint-rules/
```

Run manually:
```bash
ansible-lint ansible/
```

Run via pre-commit:
```bash
pre-commit run ansible-lint --all-files
```

## Adding New Verbs

1. Edit `tools/approved-ansible-verbs.yml`
2. Add the new verb in alphabetical order
3. Document the decision (link to MR/issue if applicable)
4. The lint rule will automatically pick up the change

## File Structure

```
tools/
├── approved-ansible-verbs.yml    # Source of truth for approved verbs
├── lint-rules/
│   ├── __init__.py              # Module initialization
│   ├── playbook_naming.py       # ORG001 rule implementation
│   └── README.md                # This file
```

## Adding New Rules

To add a new custom rule:

1. Create a new Python file in this directory (e.g., `role_naming.py`)
2. Import and extend `AnsibleLintRule`
3. Assign a unique ID (e.g., `ORG002`)
4. Export it in `__init__.py`
5. Document it in this README

## Testing Rules

Create test playbooks to verify rules work:

```bash
# Test with a bad name
echo "- hosts: all" > ansible/playbooks/bad-name.yml
ansible-lint ansible/playbooks/bad-name.yml

# Should fail with ORG001 violation
```

## References

- [Ansible Lint Documentation](https://ansible.readthedocs.io/projects/lint/)
- [Custom Rules Guide](https://ansible.readthedocs.io/projects/lint/rules/custom/)
- Internal naming standard: `~/Downloads/ansible_naming_standard.md`
