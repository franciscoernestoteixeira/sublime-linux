# Sublime Linux Installer

> Simple, safe installer for **Sublime Text** and **Sublime Merge** on Linux  
> Using the **official .tar.xz builds**, without package managers.

---

## TL;DR

Install **Sublime Text** (default):

```bash
curl -LO https://raw.githubusercontent.com/franciscoernestoteixeira/sublime-linux/main/install-sublime.sh && chmod +x install-sublime.sh && ./install-sublime.sh
```

Install **Sublime Merge only**:

```bash
./install-sublime.sh --only merge
```

Install **both**:

```bash
./install-sublime.sh --only both
```

Preview what will happen (no changes):

```bash
./install-sublime.sh --dry-run
```

Uninstall **Sublime Text** (default target):

```bash
./install-sublime.sh --uninstall
```

Uninstall **both**:

```bash
./install-sublime.sh --uninstall --only both
```

---

## What is this?

This repository provides a **single script** (`install-sublime.sh`) that installs:

- **Sublime Text**
- **Sublime Merge**

using the **official Linux 64-bit tarballs** from Sublime HQ.

It avoids common problems with:
- broken RPM repositories (Fedora 43+)
- outdated Flatpak builds
- Snap sandbox limitations

No `sudo`.  
No system files touched.  
Everything stays inside your home directory.

---

## What the script does

When you run `install-sublime.sh`, it will:

- Download the **latest official Linux 64-bit builds**
- Install them into:

```
~/Applications/
```

- Use **versioned folders**, for example:

```
sublime_text_build_4200_x64/
sublime_merge_build_2121_x64/
```

- Create stable symlinks:

```
sublime_text-current
sublime_merge-current
```

- Create command-line launchers:
  - `subl`
  - `smerge`

- Create desktop shortcuts:
  - **Sublime Text**
  - **Sublime Merge**

- Create an updater command:
  - `update-sublime`

---

## Requirements

- Linux (any modern distribution)
- Internet connection
- Common tools (already installed on most systems):
  - `bash`
  - `curl`
  - `tar`

---

## Installation (beginner friendly)

### Step 1 — Download the installer

```bash
cd ~/Downloads
curl -LO https://raw.githubusercontent.com/franciscoernestoteixeira/sublime-linux/main/install-sublime.sh
```

---

### Step 2 — Make it executable

```bash
chmod +x install-sublime.sh
```

---

### Step 3 — Run it

By default, this installs **Sublime Text only**:

```bash
./install-sublime.sh
```

---

## Options (quick reference)

| Option | Description |
|------|-------------|
| *(no flags)* | Install **Sublime Text** only (default) |
| `--only text` | Install **Sublime Text** only |
| `--only merge` | Install **Sublime Merge** only |
| `--only both` | Install **both** Sublime Text and Merge |
| `--clean-old` | Remove older versioned folders after install |
| `--dry-run` | Show what would happen, without changes |
| `--uninstall` | Uninstall what you selected with `--only` (default target is Text) |

Options can be combined:

```bash
./install-sublime.sh --only both --clean-old
./install-sublime.sh --only merge --dry-run
./install-sublime.sh --uninstall --only merge
./install-sublime.sh --uninstall --only both --dry-run
```

---

## Updating later

To update what you previously installed:

```bash
update-sublime
```

The updater preserves your original install options (except `--dry-run`).

---

## Installed file layout

```
~/Applications/
├── sublime_text_build_4200_x64/
├── sublime_text-current -> sublime_text_build_4200_x64
├── sublime_merge_build_2121_x64/
├── sublime_merge-current -> sublime_merge_build_2121_x64
├── .cache/sublime/
│   ├── sublime_text.tar.xz
│   └── sublime_merge.tar.xz
└── install-sublime.sh
```

Other locations:

```
~/.local/bin/
  subl
  smerge
  update-sublime

~/.local/share/applications/
  subl.desktop
  smerge.desktop
```

---

## Uninstalling

Recommended (uses the script):

Uninstall **Sublime Text**:

```bash
./install-sublime.sh --uninstall
```

Uninstall **Sublime Merge**:

```bash
./install-sublime.sh --uninstall --only merge
```

Uninstall **both**:

```bash
./install-sublime.sh --uninstall --only both
```

Preview uninstall without changes:

```bash
./install-sublime.sh --uninstall --only both --dry-run
```

The script does **not** remove your user configuration files (settings, plugins).

---

## License

MIT License.
