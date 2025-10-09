# Release Notes - v0.0.1

**Release Date:** 2025-10-09
**Full Version:** 0.0.1-alpha.60+60+22b3137

## What's Changed

- feat: add automated release creation script (22b3137)
- anthropic write golan implementation of gitversion, gitversion-go (61c8128)
- update tests and README for gitversion-sh (cda4fab)
- docs: comprehensive GitFlow workflow and configuration guide for gitversion-sh (7e13b28)
- feat: enhance gitversion.sh with comprehensive GitVersion compatibility (63fb61e)
- feat: recreate gitversion-sh test suite (6d192be)
- feat: add gitversion-sh tests directory structure (e2722d6)
- updates to gitversion-sh, including tests and configs in yaml AND json (e0e286b)
- update to gitversion.sh (d5e0b3b)
- update readme (eb8be5f)

## Installation

```bash
# Download the latest release
curl -L -o gitversion https://github.com/VirtuallyScott/battle-tested-devops/releases/download/v0.0.1/gitversion-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)
chmod +x gitversion
sudo mv gitversion /usr/local/bin/
```

## Verification

```bash
gitversion --version
# Should output: v0.0.1
```

---

For detailed documentation, see the [README](README.md).
For issues or questions, please visit the [GitHub repository](https://github.com/VirtuallyScott/battle-tested-devops).
