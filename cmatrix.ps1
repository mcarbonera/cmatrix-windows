
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class MatrixLauncherFixed
{
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", EntryPoint = "GetWindowLongPtrW")]
    public static extern IntPtr GetWindowLongPtr(IntPtr hWnd, int index);

    [DllImport("user32.dll", EntryPoint = "SetWindowLongPtrW")]
    public static extern IntPtr SetWindowLongPtr(IntPtr hWnd, int index, IntPtr value);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetWindowPos(
        IntPtr hWnd, IntPtr insertAfter,
        int x, int y, int width, int height, uint flags);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int command);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    public static IntPtr FindWindowByTitle(string title)
    {
        IntPtr found = IntPtr.Zero;

        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            if (!IsWindowVisible(hWnd)) return true;

            StringBuilder text = new StringBuilder(512);
            GetWindowText(hWnd, text, text.Capacity);

            if (text.ToString().Contains(title))
            {
                found = hWnd;
                return false;
            }
            return true;
        }, IntPtr.Zero);

        return found;
    }
}
"@

Add-Type -AssemblyName System.Windows.Forms

$screens = @(
    [System.Windows.Forms.Screen]::AllScreens |
    Sort-Object { $_.Bounds.X }
)

if ($screens.Count -lt 2) {
    throw "Foram detectados menos de dois monitores."
}

for ($i = 0; $i -lt 2; $i++) {
    $s = $screens[$i]
    $title = "CMATRIX-SCREEN-$i"

    Start-Process wt.exe -ArgumentList @(
        '-w', 'new',
        '--pos', "$($s.Bounds.X),$($s.Bounds.Y)",
        '--fullscreen',
        'new-tab',
        '--title', $title,
        '--suppressApplicationTitle',
        'wsl.exe', '-e', 'cmatrix'
    )

    Start-Sleep -Seconds 2
}

# Localiza o mintty.exe ancestral do PowerShell
$currentPid = $PID
$minttyPid = $null

for ($i = 0; $i -lt 10 -and $currentPid; $i++) {
    $proc = Get-CimInstance Win32_Process `
        -Filter "ProcessId = $currentPid" `
        -ErrorAction SilentlyContinue

    if (-not $proc) { break }

    if ($proc.Name -ieq 'mintty.exe') {
        $minttyPid = [int]$proc.ProcessId
        break
    }

    $currentPid = [int]$proc.ParentProcessId
}

# Minimiza a janela do Git Bash pelo título
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class GitBashMinimizer {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(
        EnumWindowsProc callback, IntPtr lParam);

    public delegate bool EnumWindowsProc(
        IntPtr hwnd, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(
        IntPtr hwnd, StringBuilder text, int count);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hwnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(
        IntPtr hwnd, int command);

    public static bool MinimizeByTitle(string prefix) {
        bool found = false;

        EnumWindows(delegate(IntPtr hwnd, IntPtr lParam) {
            if (!IsWindowVisible(hwnd)) return true;

            StringBuilder title = new StringBuilder(512);
            GetWindowText(hwnd, title, title.Capacity);

            if (title.ToString().StartsWith(
                prefix, StringComparison.OrdinalIgnoreCase)) {
                ShowWindowAsync(hwnd, 6);
                found = true;
                return false;
            }

            return true;
        }, IntPtr.Zero);

        return found;
    }
}
"@

if (-not [GitBashMinimizer]::MinimizeByTitle("MINGW64:")) {
    Write-Warning "Não encontrei uma janela com título começando por MINGW64:."
}