# Automate SSL Certificate Request and Optionally Submit to ZeroSSL for a Free Certificate and Install It on the Machine After Retrieval

## Overview
This PowerShell script automates the entire process of generating a Certificate Signing Request (CSR), verifying and installing necessary tools, and optionally submitting the CSR to ZeroSSL to obtain a free SSL certificate. It also allows installing the certificate on the machine after retrieval.

## Features
- **Automatic tool verification**: Checks for `certreq.exe` and installs the required Windows SDK or RSAT tools if missing.
- **CSR Generation**: Uses `certreq.exe` to generate a CSR.
- **Data Validation**: Validates country and city names using public APIs.
- **ZeroSSL Integration**: Optionally submits the CSR to [ZeroSSL](https://zerossl.com) to obtain a free SSL certificate.
- **Storage Management**: Saves the certificate in the same directory as the CSR.
- **Automatic Installation**: Offers the option to install the certificate on the local machine.
- **Customizable settings**: Allows users to configure key length and certificate validity period.

## Prerequisites
### 1. Ensure Required Tools Are Installed
The script automatically checks for `certreq.exe`. If missing, it prompts the user to install the required Windows SDK or RSAT tools.
To manually verify if `certreq.exe` is available, run:
```powershell
Get-Command certreq.exe
```
If not found, the script will guide you through the installation process.

### 2. Obtain a ZeroSSL API Key
To submit a CSR to ZeroSSL, follow these steps:
1. Create a free account on [ZeroSSL](https://app.zerossl.com/signup).
2. Log in to your account.
3. Navigate to **Developer > API Access**.
4. Generate an API key and copy it.
5. Replace `your_zerossl_api_key_here` in the script with your actual API key.

### 3. (Optional) Obtain an OpenWeatherMap API Key
If city validation is required, obtain an API key from [OpenWeatherMap](https://home.openweathermap.org/users/sign_up) and replace `your_api_key_here` in the script.

## Installation
1. **Download the script**: [Generate-CSR-ZeroSSL.ps1](path-to-your-repo/Generate-CSR-ZeroSSL.ps1)
2. **Run PowerShell as Administrator**.
3. **Navigate to the script directory**:
   ```powershell
   cd path-to-your-repo
   ```
4. **Execute the script**:
   ```powershell
   .\Generate-CSR-ZeroSSL.ps1
   ```

## Usage
The script will prompt you for the following details:
- **Common Name (CN)** (e.g., www.example.com)
- **Organization Name (O)**
- **Organizational Unit (OU)**
- **City and State**
- **Country Code**
- **Subject Alternative Names (SANs)**
- **Key Length**
- **Certificate Validity Period**
- **Private Key Password** (optional)

### Submitting CSR to ZeroSSL
If you choose to submit the CSR to ZeroSSL:
1. **Enter your email** for registration.
2. **Wait for domain validation** email from ZeroSSL.
3. **Complete domain validation** via DNS, HTTP, or email verification.
4. **Retrieve your certificate** from ZeroSSL.

### Installing the Certificate
If you opt to install the certificate:
1. The script will attempt to install it automatically using:
   ```powershell
   certreq.exe -accept "C:\path\to\certificate.crt"
   ```
2. To manually verify the installation, run:
   ```powershell
   Get-ChildItem -Path Cert:\LocalMachine\My | Format-List Subject
   ```

## Troubleshooting
### Certreq Not Found
The script automatically detects missing tools and guides you through installation. If needed, manually install Windows SDK or RSAT tools.

### API Errors
Ensure that your ZeroSSL API key is correct and that you have a stable internet connection.

### Certificate Not Installed
If the automatic installation fails, install the certificate manually using:
```powershell
Import-Certificate -FilePath "C:\path\to\certificate.crt" -CertStoreLocation Cert:\LocalMachine\My
```

## License
This project is licensed under the MIT License. See the LICENSE file for details.

