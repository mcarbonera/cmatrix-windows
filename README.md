# CMatrix Dual-Monitor Screensaver

Runs `cmatrix` inside WSL across two monitors, using Windows Terminal in full-screen mode to create a screensaver-like effect. The launcher automatically minimizes Git Bash after startup.

## Requirements

- Windows with two monitors
- WSL with `cmatrix` installed
- Windows Terminal
- Git Bash and PowerShell

## Setup

1. Install `cmatrix` in WSL:

   ```bash
   sudo apt update && sudo apt install cmatrix
   ```

2. Create `~/bin` in Git Bash and add it to your `PATH`:

   ```bash
   mkdir -p ~/bin
   echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

3. Save the Bash wrapper as `~/bin/cmatrix`:

   ```bash
   #!/usr/bin/env bash
   powershell.exe -NoProfile -ExecutionPolicy Bypass \
     -File "$(cygpath -w "$HOME/bin/cmatrix.ps1")" "$@"
   ```

4. Make it executable:

   ```bash
   chmod +x ~/bin/cmatrix
   ```

5. Save the PowerShell launcher as `~/bin/cmatrix.ps1`.

## Usage

Run from Git Bash:

```bash
cmatrix
```

The launcher opens `cmatrix` on both monitors in full-screen Windows Terminal windows and minimizes Git Bash.

**Note:** This is a screensaver-like effect; it does not automatically activate after inactivity.