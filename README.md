# Enccrypton 🔒

A secure PowerShell-based folder encryption tool designed for enterprise communications. Enccrypton provides end-to-end encrypted data transfer capabilities with a focus on security and ease of use.

## Features ✨

- Folder encryption with AES-256 encryption
- Secure password-based key derivation
- User-friendly GUI for folder/file selection
- Enterprise-grade security protocols
- Network traffic protection
- Compressed storage using ZIP format

## Requirements 📋

- Windows PowerShell 5.1 or higher
- .NET Framework 4.7.2 or higher
- Windows 7/10/11

## Installation 💻

1. Clone the repository:
```powershell
git clone https://github.com/yourusername/enccrypton.git
```

2. Navigate to the project directory:
```powershell
cd enccrypton
```

3. Run the script in PowerShell:
```powershell
.\Enccrypton.ps1
```

## Usage 🚀

1. Launch the application in PowerShell
2. Choose from the following options:
   - Encrypt a folder
   - Decrypt a file
   - Exit

### Encrypting a Folder
1. Select option 1 from the main menu
2. Enter an encryption password
3. Select the folder you want to encrypt
4. The encrypted file will be saved with a `.secure` extension

### Decrypting a File
1. Select option 2 from the main menu
2. Select the `.secure` file you want to decrypt
3. Enter the decryption password
4. Files will be extracted to a new folder with "_Decrypted" suffix

## Security Considerations 🛡️

- Uses AES-256 encryption
- Implements secure password-based key derivation (PBKDF2)
- Securely handles encryption keys in memory
- Properly disposes of cryptographic resources

## Contributing 🤝

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License 📄

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Author ✍️

**NMJlessons**

## Disclaimer ⚠️

This software is provided "as is", without warranty of any kind. Use at your own risk.

---

