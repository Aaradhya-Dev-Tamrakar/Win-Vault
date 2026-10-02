Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Set current location to script directory
Set-Location -LiteralPath $PSScriptRoot

$vaultDir      = Join-Path $PSScriptRoot 'PrivateVault'
$lockedDir     = Join-Path $PSScriptRoot '.PrivateVault_Locked'
$clsidDir      = Join-Path $PSScriptRoot 'PrivateVault.{21EC2020-3AEA-1069-A2DD-08002B30309D}'
$legacyDir     = Join-Path $PSScriptRoot 'Private'
$cfgFile       = Join-Path $PSScriptRoot '.vault_key.dat'

# Auto-migrate legacy names
if (Test-Path -LiteralPath $clsidDir) {
    Rename-Item -LiteralPath $clsidDir -NewName '.PrivateVault_Locked' -Force
}
if ((Test-Path -LiteralPath $legacyDir) -and (-not (Test-Path -LiteralPath $vaultDir)) -and (-not (Test-Path -LiteralPath $lockedDir))) {
    Rename-Item -LiteralPath $legacyDir -NewName 'PrivateVault' -Force
}

function Get-PasswordHash($plainText) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($plainText)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha.ComputeHash($bytes)
    return [System.BitConverter]::ToString($hashBytes).Replace('-', '')
}

function Set-AclLock($folderPath) {
    try {
        $item = Get-Item -LiteralPath $folderPath -Force
        $acl = $item.GetAccessControl()
        $sid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::WorldSid, $null)
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $sid,
            [System.Security.AccessControl.FileSystemRights]::FullControl,
            [System.Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit',
            [System.Security.AccessControl.PropagationFlags]::None,
            [System.Security.AccessControl.AccessControlType]::Deny
        )
        $acl.AddAccessRule($rule)
        $item.SetAccessControl($acl)
    } catch {}
}

function Remove-AclLock($folderPath) {
    try {
        $item = Get-Item -LiteralPath $folderPath -Force
        $acl = $item.GetAccessControl()
        $sid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::WorldSid, $null)
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $sid,
            [System.Security.AccessControl.FileSystemRights]::FullControl,
            [System.Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit',
            [System.Security.AccessControl.PropagationFlags]::None,
            [System.Security.AccessControl.AccessControlType]::Deny
        )
        $acl.RemoveAccessRule($rule) | Out-Null
        $item.SetAccessControl($acl)
    } catch {}
}

function Set-HiddenAndSystem($path) {
    try {
        $item = Get-Item -LiteralPath $path -Force
        $item.Attributes = [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System
    } catch {}
}

function Clear-HiddenAndSystem($path) {
    try {
        $item = Get-Item -LiteralPath $path -Force
        $item.Attributes = [System.IO.FileAttributes]::Directory -bor [System.IO.FileAttributes]::Normal
    } catch {}
}

function Show-PasswordInputForm($title, $headerText, $buttonText='OK') {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $title
    $form.Size = New-Object System.Drawing.Size(380, 190)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true
    $form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $headerText
    $lbl.Location = New-Object System.Drawing.Point(25, 18)
    $lbl.Size = New-Object System.Drawing.Size(320, 25)
    $form.Controls.Add($lbl)

    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Location = New-Object System.Drawing.Point(25, 48)
    $txt.Size = New-Object System.Drawing.Size(315, 25)
    $txt.PasswordChar = [char]0x25CF
    $form.Controls.Add($txt)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = $buttonText
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $btnOk.Location = New-Object System.Drawing.Point(150, 95)
    $btnOk.Size = New-Object System.Drawing.Size(90, 32)
    $form.Controls.Add($btnOk)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = 'Cancel'
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $btnCancel.Location = New-Object System.Drawing.Point(250, 95)
    $btnCancel.Size = New-Object System.Drawing.Size(90, 32)
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOk
    $form.CancelButton = $btnCancel

    $res = $form.ShowDialog()
    if ($res -eq [System.Windows.Forms.DialogResult]::OK) {
        return $txt.Text
    }
    return $null
}

function Show-UnlockedOptionsForm() {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Win-Vault Manager'
    $form.Size = New-Object System.Drawing.Size(420, 210)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true
    $form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Your Vault ('PrivateVault') is currently UNLOCKED.`nChoose an action:"
    $lbl.Location = New-Object System.Drawing.Point(25, 20)
    $lbl.Size = New-Object System.Drawing.Size(360, 40)
    $form.Controls.Add($lbl)

    $btnLock = New-Object System.Windows.Forms.Button
    $btnLock.Text = '🔒 Lock Vault'
    $btnLock.Location = New-Object System.Drawing.Point(25, 75)
    $btnLock.Size = New-Object System.Drawing.Size(110, 35)
    $btnLock.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $form.Controls.Add($btnLock)

    $btnOpen = New-Object System.Windows.Forms.Button
    $btnOpen.Text = '📂 Open Folder'
    $btnOpen.Location = New-Object System.Drawing.Point(145, 75)
    $btnOpen.Size = New-Object System.Drawing.Size(110, 35)
    $btnOpen.DialogResult = [System.Windows.Forms.DialogResult]::No
    $form.Controls.Add($btnOpen)

    $btnChange = New-Object System.Windows.Forms.Button
    $btnChange.Text = '🔑 Change Pass'
    $btnChange.Location = New-Object System.Drawing.Point(265, 75)
    $btnChange.Size = New-Object System.Drawing.Size(120, 35)
    $btnChange.DialogResult = [System.Windows.Forms.DialogResult]::Retry
    $form.Controls.Add($btnChange)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = 'Close'
    $btnClose.Location = New-Object System.Drawing.Point(295, 125)
    $btnClose.Size = New-Object System.Drawing.Size(90, 30)
    $btnClose.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnClose)

    $form.AcceptButton = $btnLock
    $form.CancelButton = $btnClose

    return $form.ShowDialog()
}

# Ensure config file is hidden if it exists
if (Test-Path -LiteralPath $cfgFile) {
    Set-HiddenAndSystem $cfgFile
}

# --- 1. FIRST-TIME SETUP ---
if (-not (Test-Path -LiteralPath $cfgFile)) {
    $p1 = Show-PasswordInputForm 'Win-Vault Setup' 'Create a Master Password for your Vault:' 'Save'
    if ([string]::IsNullOrWhiteSpace($p1)) { exit }

    $p2 = Show-PasswordInputForm 'Win-Vault Setup' 'Confirm Master Password:' 'Confirm'
    if ($p1 -ne $p2) {
        [System.Windows.Forms.MessageBox]::Show('Passwords do not match. Setup cancelled.', 'Setup Error', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        exit
    }

    $hash = Get-PasswordHash $p1
    Set-Content -LiteralPath $cfgFile -Value $hash -Force
    Set-HiddenAndSystem $cfgFile

    if (-not (Test-Path -LiteralPath $vaultDir)) {
        New-Item -ItemType Directory -Path $vaultDir | Out-Null
    }

    [System.Windows.Forms.MessageBox]::Show("Setup complete!`n`nFolder 'PrivateVault' is ready. Place your files inside and run Vault.bat to lock it.", 'Win-Vault Ready', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    Invoke-Item $vaultDir
    exit
}

# --- 2. VAULT IS CURRENTLY UNLOCKED ---
if (Test-Path -LiteralPath $vaultDir) {
    $action = Show-UnlockedOptionsForm
    
    # Action: LOCK
    if ($action -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            Rename-Item -LiteralPath $vaultDir -NewName '.PrivateVault_Locked' -ErrorAction Stop
            Set-HiddenAndSystem $lockedDir
            Set-AclLock $lockedDir
            [System.Windows.Forms.MessageBox]::Show('Vault is now locked and protected with NTFS ACL permissions.', 'Vault Locked', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to lock vault. Please ensure no files inside 'PrivateVault' are open in other programs.`n`nDetails: $($_.Exception.Message)", 'Lock Error', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
        exit
    }

    # Action: OPEN
    if ($action -eq [System.Windows.Forms.DialogResult]::No) {
        Invoke-Item $vaultDir
        exit
    }

    # Action: CHANGE PASSWORD
    if ($action -eq [System.Windows.Forms.DialogResult]::Retry) {
        $currPass = Show-PasswordInputForm 'Verify Password' 'Enter Current Master Password:' 'Verify'
        if ($null -eq $currPass) { exit }

        $storedHash = (Get-Content -LiteralPath $cfgFile -Raw).Trim()
        if ((Get-PasswordHash $currPass) -ne $storedHash) {
            [System.Windows.Forms.MessageBox]::Show('Current password incorrect.', 'Authentication Failed', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            exit
        }

        $newP1 = Show-PasswordInputForm 'New Password' 'Enter New Master Password:' 'Save'
        if ([string]::IsNullOrWhiteSpace($newP1)) { exit }
        $newP2 = Show-PasswordInputForm 'New Password' 'Confirm New Master Password:' 'Confirm'

        if ($newP1 -ne $newP2) {
            [System.Windows.Forms.MessageBox]::Show('Passwords do not match. Password unchanged.', 'Error', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            exit
        }

        Clear-HiddenAndSystem $cfgFile
        Set-Content -LiteralPath $cfgFile -Value (Get-PasswordHash $newP1) -Force
        Set-HiddenAndSystem $cfgFile
        [System.Windows.Forms.MessageBox]::Show('Master password updated successfully.', 'Password Changed', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        exit
    }

    exit
}

# --- 3. VAULT IS CURRENTLY LOCKED -> UNLOCK FLOW ---
if (Test-Path -LiteralPath $lockedDir) {
    $storedHash = (Get-Content -LiteralPath $cfgFile -Raw).Trim()
    $maxAttempts = 3
    $attempt = 0

    while ($attempt -lt $maxAttempts) {
        $passInput = Show-PasswordInputForm 'Unlock Win-Vault' 'Enter Master Password to Unlock:' 'Unlock'
        if ($null -eq $passInput) { exit }

        if ((Get-PasswordHash $passInput) -eq $storedHash) {
            try {
                Remove-AclLock $lockedDir
                Clear-HiddenAndSystem $lockedDir
                Rename-Item -LiteralPath $lockedDir -NewName 'PrivateVault' -ErrorAction Stop
                Invoke-Item $vaultDir
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to unlock vault cleanly. Error: $($_.Exception.Message)", 'Unlock Error', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
            exit
        } else {
            $attempt++
            $remaining = $maxAttempts - $attempt
            if ($remaining -gt 0) {
                [System.Windows.Forms.MessageBox]::Show("Incorrect password!`nRemaining attempts: $remaining", 'Access Denied', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            } else {
                [System.Windows.Forms.MessageBox]::Show('Too many failed attempts. Vault remains locked.', 'Lockout', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Stop)
                exit
            }
        }
    }
    exit
}

# Fallback: create if neither exists
New-Item -ItemType Directory -Path $vaultDir | Out-Null
[System.Windows.Forms.MessageBox]::Show("Vault directory initialized at '$vaultDir'.", 'Ready', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
Invoke-Item $vaultDir
