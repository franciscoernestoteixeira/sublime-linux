# Sublime Linux Installer

> Simple, safe installer for **Sublime Text** and **Sublime Merge** on Linux  
> Using the **official .tar.xz builds**, without package managers.

---

## 🇺🇸 English

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

```
cd ~/Downloads
curl -LO https://raw.githubusercontent.com/<YOUR_GITHUB_USERNAME>/sublime-linux/main/install-sublime.sh
```

Replace `<YOUR_GITHUB_USERNAME>` with your GitHub username.

---

### Step 2 — Make it executable

```
chmod +x install-sublime.sh
```

---

### Step 3 — Run it

```
./install-sublime.sh
```

That’s all.

---

## Updating later

To update both applications to the latest version:

```
update-sublime
```

---

## Optional flags

### --clean-old

Removes **older versioned folders** after a successful update, keeping only:

- the latest installed version
- the `*-current` symlink

Example:

```
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

## Screenshots

Place screenshots under:

```
docs/screenshots/
```

Example references:

```
docs/screenshots/menu.png
docs/screenshots/sublime-text.png
docs/screenshots/sublime-merge.png
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

---

## 🇧🇷 Português (Brasil)

### O que é isso?

Este repositório fornece um **script único** (`install-sublime.sh`) para instalar:

- **Sublime Text**
- **Sublime Merge**

usando os **binários oficiais (.tar.xz)** da Sublime HQ.

Evita problemas comuns como:
- repositórios RPM quebrados (Fedora 43+)
- Flatpak desatualizado
- limitações do Snap

Sem `sudo`.  
Sem alterações no sistema.  
Tudo fica dentro do seu usuário.

---

### Como instalar

```
cd ~/Downloads
curl -LO https://raw.githubusercontent.com/<SEU_USUARIO_GITHUB>/sublime-linux/main/install-sublime.sh
chmod +x install-sublime.sh
./install-sublime.sh
```

---

### Atualizar depois

```
update-sublime
```

---

### Opção extra

```
./install-sublime.sh --clean-old
```

---

## Licença

MIT License.
