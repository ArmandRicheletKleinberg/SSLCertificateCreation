# Function to check if certreq.exe is available
function Check-CertReq {
    $certreqPath = (Get-Command certreq.exe -ErrorAction SilentlyContinue).Source
    if (-not $certreqPath) {
        Write-Host "certreq.exe not found. Please install Windows RSAT tools or a Windows SDK."
        exit 1
    }
    return $certreqPath
}

# Function to validate country code using an API
function Validate-Country($countryCode) {
    try {
        $response = Invoke-RestMethod -Uri "https://restcountries.com/v3.1/alpha/$countryCode"
        if ($response) {
            return $true
        }
    } catch {
        return $false
    }
}

# Function to validate city using OpenWeatherMap API
function Validate-City($city, $countryCode) {
    try {
        $apiKey = "your_api_key_here"  # Replace with a real API key from OpenWeatherMap
        $response = Invoke-RestMethod -Uri "http://api.openweathermap.org/data/2.5/weather?q=$city,$countryCode&appid=$apiKey"
        if ($response) {
            return $true
        }
    } catch {
        return $false
    }
}

# Function to submit CSR to ZeroSSL API
function Request-ZeroSSL-Certificate($csrPath, $email, $validityDays) {
    $apiKey = "your_zerossl_api_key_here"  # Replace with your ZeroSSL API key
    $csrContent = Get-Content -Path $csrPath -Raw
    $csrEncoded = [System.Web.HttpUtility]::UrlEncode($csrContent)

    $apiUrl = "https://api.zerossl.com/certificates?access_key=$apiKey"

    $body = @{
        certificate_domains = $CommonName
        certificate_csr = $csrEncoded
        certificate_validity_days = $validityDays
        certificate_email = $email
    }

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $body
        if ($response.success -eq $true) {
            return $response.id  # Return certificate ID
        } else {
            Write-Host "ZeroSSL request failed: $($response.error.message)"
            return $null
        }
    } catch {
        Write-Host "Error requesting certificate from ZeroSSL: $_"
        return $null
    }
}

# Prompt user for certificate details with default values
$CommonName = Read-Host "Enter the Common Name (e.g., www.example.com)"
$Organization = Read-Host "Enter the Organization Name (e.g., Example Corp)"
$OrganizationalUnit = Read-Host "Enter the Organizational Unit (e.g., IT Department)"
$City = Read-Host "Enter the City or Locality (Default: New York)" -Default "New York"
$State = Read-Host "Enter the State or Province (e.g., NY)"  -Default "NY"
$Country = Read-Host "Enter the Country Code (2-letter, Default: US)" -Default "US"
$SANs = Read-Host "Enter Subject Alternative Names (SANs) as comma-separated list (e.g., www.example.com, sftp.example.com)"
$KeyLength = Read-Host "Enter the Key Length (Default: 2048)" -Default "2048"
$ValidityDays = Read-Host "Enter Certificate Validity Period (Default: 90 days)" -Default "90"
$PrivateKeyPassword = Read-Host "Enter a password to protect the private key (leave blank for no password)"

# Validate country code
if (-not (Validate-Country $Country)) {
    Write-Host "Invalid country code. Please enter a valid 2-letter country code."
    exit 1
}


# Check if certreq.exe is available
$certreqPath = Check-CertReq

# Create the INF file content
$infContent = @"
[Version]
Signature="\`$Windows NT\`$"

[NewRequest]
Subject = "CN=$CommonName, O=$Organization, OU=$OrganizationalUnit, L=$City, S=$State, C=$Country"
KeySpec = 1
KeyLength = $KeyLength
Exportable = TRUE
MachineKeySet = TRUE
SMIME = FALSE
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0
HashAlgorithm = SHA256

[EnhancedKeyUsageExtension]
OID=1.3.6.1.5.5.7.3.1 ; Server Authentication
OID=1.3.6.1.5.5.7.3.2 ; Client Authentication

[Extensions]
2.5.29.17 = "{text}"
"@

# Add Subject Alternative Names (SANs) if provided
if ($SANs) {
    $sanList = $SANs -split ",\s*"
    foreach ($san in $sanList) {
        $infContent += "DNS=$san`r`n"
    }
}

# Define file paths
$infPath = "$env:TEMP\request.inf"
$csrPath = "$env:TEMP\$CommonName.csr"
$keyPath = "$env:TEMP\$CommonName.key"

# Save the INF content to a file
$infContent | Out-File -FilePath $infPath -Encoding ASCII

# Generate the CSR
certreq.exe -new $infPath $csrPath

Write-Host "`nCSR generated successfully:"
Write-Host "CSR Path: $csrPath"

# Ask user if they want to submit to ZeroSSL
$submitToZeroSSL = Read-Host "Do you want to submit this CSR to ZeroSSL for a free SSL certificate? (yes/no)"
if ($submitToZeroSSL -eq "yes") {
    $email = Read-Host "Enter your email for ZeroSSL registration"
    $certificateID = Request-ZeroSSL-Certificate -csrPath $csrPath -email $email -validityDays $ValidityDays
    if ($certificateID) {
        Write-Host "Certificate requested successfully! ZeroSSL Certificate ID: $certificateID"
        Write-Host "Please check your email and ZeroSSL account to complete domain validation."
    }
}

# Ask user if they want to install the certificate
$installCert = Read-Host "Do you want to install the certificate on this machine? (yes/no)"
if ($installCert -eq "yes") {
    certreq.exe -accept "$env:TEMP\$CommonName.crt"
    Write-Host "Certificate installed successfully."
}

# Cleanup
Remove-Item -Path $infPath
