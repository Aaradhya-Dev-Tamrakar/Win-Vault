# Win-Vault 🔒

A lightweight, zero-dependency, GUI-driven Windows folder locker and privacy vault.

---

## ✨ Features

- **🎨 Modern Windows Native GUI**: Dialog prompts with masked bullet (`●●●●`) password inputs.
- **⚡ Zero Setup Required**: Just double-click `Vault.bat`. On first launch, a setup wizard prompts you to set and confirm your master password.
- **🔐 SHA-256 Hashing**: Never stores your plaintext password. Only cryptographic hashes are recorded in `.vault_key.dat`.
- **🛡️ Multi-Tier Protection**:
  1. **NTFS ACL Deny (`icacls`)**: Denies low-level read/write/traversal permissions directly at the Windows kernel filesystem level.
  2. **CLSID Shell Disguise**: Obscures the folder as the Windows Control Panel extension (`{21EC2020-3AEA-1069-A2DD-08002B30309D}`).
  3. **Hidden & System Flags**: Applies `+h +s` attributes.
- **📂 Auto-Open**: Automatically launches File Explorer directly into `PrivateVault` upon successful unlock.
- **🔑 In-App Password Management**: Change your master password anytime directly from the unlocked GUI manager.
- **🚫 Brute-Force Rate Limiting**: Locks out after 3 consecutive failed attempts.

---

## 🚀 How to Use

1. **First Launch**:
   - Double-click [`Vault.bat`](file:///F:/Aaradhya-Dev-Tamrakar/Win-Vault/Vault.bat).
   - Enter and confirm your new Master Password.
   - `PrivateVault` folder opens automatically. Place any private files inside.

2. **Locking**:
   - Double-click [`Vault.bat`](file:///F:/Aaradhya-Dev-Tamrakar/Win-Vault/Vault.bat).
   - Click **🔒 Lock Vault**.

3. **Unlocking**:
   - Double-click [`Vault.bat`](file:///F:/Aaradhya-Dev-Tamrakar/Win-Vault/Vault.bat).
   - Enter your Master Password and click **Unlock**.

4. **Change Password**:
   - Run [`Vault.bat`](file:///F:/Aaradhya-Dev-Tamrakar/Win-Vault/Vault.bat) while unlocked $\rightarrow$ click **🔑 Change Pass**.
