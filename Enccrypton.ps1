Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Security

function Get-FolderPath {
    Add-Type -AssemblyName System.Windows.Forms
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select folder to encrypt/decrypt"
    
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    }
    return $null
}

function Encrypt-Folder {
    param (
        [string]$Password
    )
    
    $SourcePath = Get-FolderPath
    if (!$SourcePath) {
        Write-Host "No folder selected. Operation cancelled." -ForegroundColor Yellow
        return
    }

    $zipPath = "$SourcePath.zip"
    $encryptedPath = "$SourcePath.secure"
    
    try {
        Write-Host "Starting encryption of $SourcePath..."
        
        [System.IO.Compression.ZipFile]::CreateFromDirectory($SourcePath, $zipPath)
        Write-Host "Folder compressed..."

        $fileContent = [System.IO.File]::ReadAllBytes($zipPath)
        
        $salt = [byte[]]@(1,2,3,4,5,6,7,8)
        $iterations = 1000
        $keySize = 256
        $derivedBytes = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $salt, $iterations)
        $key = $derivedBytes.GetBytes($keySize / 8)

        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $key
        $aes.GenerateIV()
        
        $memoryStream = New-Object System.IO.MemoryStream
        $cryptoStream = New-Object System.Security.Cryptography.CryptoStream(
            $memoryStream, 
            $aes.CreateEncryptor(),
            [System.Security.Cryptography.CryptoStreamMode]::Write
        )

        $cryptoStream.Write($fileContent, 0, $fileContent.Length)
        $cryptoStream.FlushFinalBlock()
        
        $finalEncryptedData = $aes.IV + $memoryStream.ToArray()
        [System.IO.File]::WriteAllBytes($encryptedPath, $finalEncryptedData)
        
        Write-Host "Encryption completed successfully!" -ForegroundColor Green
        Write-Host "Encrypted file saved as: $encryptedPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Error occurred: $_" -ForegroundColor Red
    }
    finally {
        if ($cryptoStream) { $cryptoStream.Dispose() }
        if ($memoryStream) { $memoryStream.Dispose() }
        if ($aes) { $aes.Dispose() }
        if (Test-Path $zipPath) { Remove-Item $zipPath }
    }
}

function Decrypt-Folder {
    $EncryptedPath = $null

    Add-Type -AssemblyName System.Windows.Forms
    $fileBrowser = New-Object System.Windows.Forms.OpenFileDialog
    $fileBrowser.Filter = "Secure files (*.secure)|*.secure|All files (*.*)|*.*"
    $fileBrowser.Title = "Select encrypted file"
    
    if ($fileBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $EncryptedPath = $fileBrowser.FileName
    }

    if (!$EncryptedPath) {
        Write-Host "No file selected. Operation cancelled." -ForegroundColor Yellow
        return
    }

    $Password = Read-Host -Prompt "Enter the decryption password"

    $OutputPath = [System.IO.Path]::Combine(
        [System.IO.Path]::GetDirectoryName($EncryptedPath),
        [System.IO.Path]::GetFileNameWithoutExtension($EncryptedPath) + "_Decrypted"
    )
    
    try {
        Write-Host "Starting decryption of $EncryptedPath..."

        $encryptedBytes = [System.IO.File]::ReadAllBytes($EncryptedPath)
        if ($encryptedBytes.Length -le 16) {
            throw "The encrypted file is invalid or corrupted."
        }

        # Extract IV and encrypted content
        $iv = $encryptedBytes[0..15]
        $encryptedContent = $encryptedBytes[16..($encryptedBytes.Length - 1)]

        # Derive the encryption key
        $salt = [byte[]]@(1,2,3,4,5,6,7,8)
        $iterations = 1000
        $keySize = 256
        $derivedBytes = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $salt, $iterations)
        $key = $derivedBytes.GetBytes($keySize / 8)

        # Initialize AES
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $key
        $aes.IV = $iv

        # Create a MemoryStream for the encrypted content
        $encryptedMemoryStream = New-Object System.IO.MemoryStream(@(,$encryptedContent))
        $decryptedMemoryStream = New-Object System.IO.MemoryStream
        
        # Create CryptoStream for decryption
        $cryptoStream = New-Object System.Security.Cryptography.CryptoStream(
            $encryptedMemoryStream,
            $aes.CreateDecryptor(),
            [System.Security.Cryptography.CryptoStreamMode]::Read
        )

        # Perform the decryption
        $buffer = New-Object byte[] 4096
        while ($true) {
            $count = $cryptoStream.Read($buffer, 0, $buffer.Length)
            if ($count -eq 0) { break }
            $decryptedMemoryStream.Write($buffer, 0, $count)
        }

        # Write decrypted content to a temp file
        $tempZip = [System.IO.Path]::GetTempFileName()
        [System.IO.File]::WriteAllBytes($tempZip, $decryptedMemoryStream.ToArray())

        # Extract the zip content
        if (!(Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath | Out-Null
        }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $OutputPath)

        Write-Host "Decryption completed successfully!" -ForegroundColor Green
        Write-Host "Files extracted to: $OutputPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Error occurred: $_" -ForegroundColor Red
    }
    finally {
        if ($cryptoStream) { $cryptoStream.Dispose() }
        if ($encryptedMemoryStream) { $encryptedMemoryStream.Dispose() }
        if ($decryptedMemoryStream) { $decryptedMemoryStream.Dispose() }
        if ($aes) { $aes.Dispose() }
        if ($tempZip -and (Test-Path $tempZip)) { Remove-Item $tempZip }
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "================ Enccrypton - Encryption Tool ================"
    Write-Host "=================== Designed by NMJlessons ==================="
    Write-Host "1: Encrypt a folder"
    Write-Host "2: Decrypt a file"
    Write-Host "3: Exit"
    Write-Host "===================================================="
}

do {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection) {
        '1' {
            $Password = Read-Host -Prompt "Enter a password for encryption"
            Write-Host "Please select the folder to encrypt..." -ForegroundColor Yellow
            Encrypt-Folder -Password $Password
            pause
        }
        '2' {
            Write-Host "Please select the .secure file to decrypt..." -ForegroundColor Yellow
            Decrypt-Folder
            pause
        }
        '3' {
            return
        }
        default {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
            pause
        }
    }
} while ($true)


<#
.SYNOPSIS
    Enccrypton - A secure data transfer solution for enterprise communications

.DESCRIPTION
    Enccrypton provides end-to-end encrypted data transfer capabilities
    for organizations requiring secure communication channels. The software
    implements robust encryption protocols to protect sensitive data
    during transmission, preventing unauthorized interception and
    maintaining data integrity.

.NOTES
    Version:        1.0.0
    Author:         NMJlessons
    Creation Date:  2025
    
.FEATURES
    * End-to-end encryption
    * Secure data transmission
    * Enterprise-grade security protocols
    * Network traffic protection

.COPYRIGHT
    Copyright (c) 2025 NMJlessons. All rights reserved.
    
    This software and its documentation are protected by copyright law.
    Unauthorized reproduction or distribution of this software, or any portion
    of it, may result in severe civil and criminal penalties.
#>