# Sublime Linux Installer

> Simple, safe installer for **Sublime Text** and **Sublime Merge** on Linux  
> Using the **official .tar.xz builds**, without package managers.

---

### What is this?

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

### What the script does

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

### Requirements

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

```bash
./install-sublime.sh
```

That’s all.

---

## Updating later

To update both applications to the latest version:

```bash
update-sublime
```

---

## Optional flags

### --clean-old

Removes **older versioned folders** after a successful update, keeping only:

- the latest installed version
- the `*-current` symlink

Example:

```bash
./install-sublime.sh --clean-old
```

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

To remove everything installed by the script:

```
rm -rf ~/Applications/sublime_text*
rm -rf ~/Applications/sublime_merge*
rm ~/.local/bin/subl ~/.local/bin/smerge ~/.local/bin/update-sublime
rm ~/.local/share/applications/subl.desktop
rm ~/.local/share/applications/smerge.desktop
```

User configuration files are **not** removed.

---

## License

MIT License.
