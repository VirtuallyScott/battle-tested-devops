"""
Custom Ansible Lint Rule: Playbook Naming Convention
Enforces verb-noun.yml naming pattern with approved verbs
"""

from ansiblelint.rules import AnsibleLintRule
from ansiblelint.file_utils import Lintable
import re
from pathlib import Path
import yaml


def load_approved_verbs():
    """Load approved verbs from YAML configuration file."""
    verbs_file = Path(__file__).parent.parent / "approved-ansible-verbs.yml"
    
    try:
        with open(verbs_file, 'r') as f:
            data = yaml.safe_load(f)
            return set(data.get('approved_verbs', []))
    except Exception as e:
        # Fallback to hardcoded verbs if file cannot be loaded
        return {
            "apply", "audit", "bootstrap", "build", "cleanup",
            "configure", "create", "deploy", "destroy", "disable",
            "enable", "harden", "initialize", "install", "migrate",
            "promote", "publish", "register", "remove", "rotate",
            "sync", "test", "update", "upgrade", "validate", "verify"
        }


APPROVED_VERBS = load_approved_verbs()


class PlaybookNamingRule(AnsibleLintRule):
    """
    Enforce playbook naming convention: verb-noun.yml
    
    Playbooks must:
    - Use lowercase only
    - Use hyphens as separators
    - Start with an approved verb from the verb list
    - Follow verb-noun pattern
    - Have .yml or .yaml extension
    
    Examples:
    - build-image.yml ✓
    - deploy-application.yml ✓
    - configure-network.yml ✓
    - run-stuff.yml ✗ (unapproved verb 'run')
    - BuildImage.yml ✗ (not lowercase)
    - deploy_app.yml ✗ (underscores instead of hyphens)
    """
    
    id = "ORG001"
    shortdesc = "Playbook must use approved verb-noun.yml naming"
    description = (
        "Playbooks must follow the verb-noun.yml naming convention "
        f"with an approved verb. Approved verbs: {', '.join(sorted(APPROVED_VERBS))}"
    )
    tags = ["formatting", "naming"]
    severity = "MEDIUM"
    version_added = "1.0.0"

    def matchtask(self, task, file=None):
        """Not used - we check filenames, not tasks."""
        return False
    
    def matchyaml(self, file: Lintable):
        """Check if playbook filename follows naming convention."""
        if not file or not file.path:
            return []
        
        path = Path(file.path)
        
        # Only check files in playbooks directory
        if "playbooks" not in path.parts:
            return []

        filename = path.name
        results = []
        
        # Must match lowercase hyphen-separated pattern
        if not re.match(r"^[a-z0-9]+-[a-z0-9-]+\.ya?ml$", filename):
            results.append(
                self.create_matcherror(
                    message=f"Playbook '{filename}' does not match verb-noun.yml pattern (lowercase, hyphen-separated)",
                    filename=file,
                )
            )
            return results

        # Extract verb (first part before hyphen)
        verb = filename.split("-")[0]
        
        # Check if verb is approved
        if verb not in APPROVED_VERBS:
            results.append(
                self.create_matcherror(
                    message=f"Playbook '{filename}' uses unapproved verb '{verb}'. See tools/approved-ansible-verbs.yml for approved verbs.",
                    filename=file,
                )
            )
        
        return results
