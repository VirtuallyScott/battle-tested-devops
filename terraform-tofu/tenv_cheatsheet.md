# `tenv` Cheatsheet

[`tenv`](https://github.com/tofuutils/tenv) is a lightweight version manager for [OpenTofu](https://opentofu.org), similar to `tfenv` for Terraform. It allows you to install, switch, and manage multiple versions of OpenTofu easily.

---

## 📦 Installation

### With Homebrew (macOS/Linuxbrew):

```sh
brew install tofuutils/tap/tenv
```

### Manual Install:

```sh
git clone https://github.com/tofuutils/tenv.git ~/.tenv
echo 'export PATH="$HOME/.tenv/bin:$PATH"' >> ~/.bashrc  # or ~/.zshrc
source ~/.bashrc
```

---

## 🔧 Basic Usage

### Install a specific version of OpenTofu:

```sh
tenv install 1.6.2
```

### List all available versions:

```sh
tenv list-remote
```

### List installed versions:

```sh
tenv list
```

### Use a specific version (for current shell):

```sh
tenv use 1.6.2
```

### Set a global version (default for all sessions):

```sh
tenv global 1.6.2
```

### Set a local version (in a project directory):

```sh
tenv local 1.6.2
```

This creates a `.tofu-version` file in the directory.

---

## 📁 Version File

`tenv` looks for a `.tofu-version` file to determine which OpenTofu version to use.

You can manually create it:

```sh
echo "1.6.2" > .tofu-version
```

---

## 🧹 Uninstall a version

```sh
tenv uninstall 1.6.2
```

---

## 📁 Directory Structure

Installed versions are typically located in:

```
~/.tenv/versions/
```

---

## 🛠 Aliasing `terraform` and `tf` to `tofu`

If you want CLI compatibility with scripts/tools that expect `terraform`:

### Option 1: Alias

```sh
alias terraform='tofu'
alias tf='tofu'
```

Add to your `~/.bashrc` or `~/.zshrc`.

### Option 2: Symlink (Global)

```sh
sudo ln -sf $(which tofu) /usr/local/bin/terraform
sudo ln -sf $(which tofu) /usr/local/bin/tf
```

Use with caution—this overrides the real Terraform binary if installed.

---

## 🧠 Notes

- `tenv` is meant specifically for OpenTofu, not Terraform.
- If you use both Terraform and OpenTofu, be mindful of symlinks or aliases.
- `tenv` supports `.tofu-version` just like `tfenv` supports `.terraform-version`.

---

## 🔗 Resources

- GitHub: [https://github.com/tofuutils/tenv](https://github.com/tofuutils/tenv)
- OpenTofu: [https://opentofu.org](https://opentofu.org)

---
