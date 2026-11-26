@echo off
setlocal EnableExtensions
title WCR Local Folder Opener Setup

echo ========================================================
echo   Workers Comp Recovery - Local Folder Opener Setup
echo ========================================================
echo.
echo This one-time setup lets WCR client links open straight
echo in Windows File Explorer (no admin rights required).
echo.

set "INSTALL_DIR=%LOCALAPPDATA%\WCRFolderOpener"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

set "PS_SCRIPT=%INSTALL_DIR%\open-wcr-folder.ps1"
set "VBS_LAUNCHER=%INSTALL_DIR%\launch.vbs"

> "%PS_SCRIPT%" (
  echo param([string]$RawUri^)
  echo Add-Type -AssemblyName System.Windows.Forms
  echo.
  echo $rel = $RawUri -replace '^wcr-folder://', ''
  echo $rel = $rel.TrimEnd('/'^)
  echo $rel = [System.Uri]::UnescapeDataString($rel^)
  echo $rel = $rel -replace '/', '\'
  echo $rel = $rel.TrimStart('\'^)
  echo.
  echo $candidates = @(^)
  echo if ($env:OneDriveCommercial^) {
  echo   $candidates += (Join-Path $env:OneDriveCommercial "Desktop\WCR"^)
  echo   $candidates += (Join-Path $env:OneDriveCommercial "WCR"^)
  echo }
  echo if ($env:OneDrive^) {
  echo   $candidates += (Join-Path $env:OneDrive "Desktop\WCR"^)
  echo   $candidates += (Join-Path $env:OneDrive "WCR"^)
  echo }
  echo $candidates += (Join-Path $env:USERPROFILE "OneDrive - Workers Comp Recovery\Desktop\WCR"^)
  echo $candidates += (Join-Path $env:USERPROFILE "OneDrive - Workers Comp Recovery\WCR"^)
  echo $candidates += (Join-Path $env:USERPROFILE "OneDrive\Desktop\WCR"^)
  echo $candidates += (Join-Path $env:USERPROFILE "Desktop\WCR"^)
  echo.
  echo Get-ChildItem -Path $env:USERPROFILE -Directory -Filter "OneDrive*" -ErrorAction SilentlyContinue ^| ForEach-Object {
  echo   $candidates += (Join-Path $_.FullName "Desktop\WCR"^)
  echo   $candidates += (Join-Path $_.FullName "WCR"^)
  echo }
  echo.
  echo $root = $null
  echo foreach ($c in ($candidates ^| Select-Object -Unique^)^) {
  echo   if ($c -and (Test-Path -LiteralPath $c -PathType Container^)^) {
  echo     $root = $c
  echo     break
  echo   }
  echo }
  echo.
  echo if (-not $root^) {
  echo   [System.Windows.Forms.MessageBox]::Show(
  echo     "Could not locate your synced OneDrive WCR folder on this PC." + "`r`nChecked OneDrive\Desktop\WCR and OneDrive\WCR.`r`nPlease make sure OneDrive is synced, or use Open in OneDrive Web.",
  echo     "WCR Local Folder Opener",
  echo     [System.Windows.Forms.MessageBoxButtons]::OK,
  echo     [System.Windows.Forms.MessageBoxIcon]::Information
  echo   ^) ^| Out-Null
  echo   exit 0
  echo }
  echo.
  echo $target = if ($rel^) { Join-Path $root $rel } else { $root }
  echo if (Test-Path -LiteralPath $target -PathType Container^) {
  echo   Start-Process explorer.exe -ArgumentList ('"' + $target + '"'^)
  echo   exit 0
  echo }
  echo.
  echo $leaf = ($rel -split '\\'^)[0]
  echo $match = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue ^| Where-Object { $_.Name -ieq $leaf } ^| Select-Object -First 1
  echo if ($match^) {
  echo   Start-Process explorer.exe -ArgumentList ('"' + $match.FullName + '"'^)
  echo   exit 0
  echo }
  echo.
  echo $ans = [System.Windows.Forms.MessageBox]::Show(
  echo   ("Folder not found locally:`r`n" + $target + "`r`n`r`nOpen the main WCR folder in File Explorer instead?"^),
  echo   "WCR Local Folder Opener",
  echo   [System.Windows.Forms.MessageBoxButtons]::YesNo,
  echo   [System.Windows.Forms.MessageBoxIcon]::Question
  echo ^)
  echo if ($ans -eq [System.Windows.Forms.DialogResult]::Yes^) {
  echo   Start-Process explorer.exe -ArgumentList ('"' + $root + '"'^)
  echo }
)

> "%VBS_LAUNCHER%" (
  echo Set sh = CreateObject("WScript.Shell"^)
  echo Set fso = CreateObject("Scripting.FileSystemObject"^)
  echo arg = ""
  echo If WScript.Arguments.Count ^> 0 Then arg = WScript.Arguments(0^)
  echo psPath = fso.GetParentFolderName(WScript.ScriptFullName^) ^& "\open-wcr-folder.ps1"
  echo q = Chr(34^)
  echo cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File " ^& q ^& psPath ^& q ^& " " ^& q ^& Replace(arg, q, ""^) ^& q
  echo sh.Run cmd, 0, False
)

reg add "HKCU\Software\Classes\wcr-folder" /ve /d "URL:WCR Local Folder Protocol" /f >nul
reg add "HKCU\Software\Classes\wcr-folder" /v "URL Protocol" /d "" /f >nul
reg add "HKCU\Software\Classes\wcr-folder\DefaultIcon" /ve /d "explorer.exe,0" /f >nul
reg add "HKCU\Software\Classes\wcr-folder\shell\open\command" /ve /d "wscript.exe \"%VBS_LAUNCHER%\" \"%%1\"" /f >nul

echo [OK] Registered wcr-folder:// protocol for current Windows user.
echo [OK] Installed helper in: %INSTALL_DIR%
echo.
echo All set! You can now click any Client Folder link in SmartSuite
echo to open that client's folder directly in Windows File Explorer.
echo (On first click, check "Always allow" in your browser prompt.)
echo.
pause
