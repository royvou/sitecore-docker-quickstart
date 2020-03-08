param (
    [Parameter()]
    [string]
    $scVersion = "9.3.0", #Only supported version currently
    
    [ValidateSet("xm", "xp", "xc")]
    [string]
    $scVariant = "xp",

    #[switch]
    [bool]
    $includeSPE = $true
)
$ErrorActionPreference = "stop"

$activeScVariant = $scVariant

if ($includeSPE) {
    $activeScVariant += ".spe"
}


## VARIABLES
$dockerProcess = "com.docker.service"

$scVersionX = $scVersion.Substring(0,4) + "x";

$ghuc = "https://raw.githubusercontent.com/Sitecore/docker-images/master/"
#TODOD: Change
$ghucSc = "$($ghuc)windows/tests/$scVersionX/"

$filesToDownload = @(
    @{src = "$($ghucSc)docker-compose.$activeScVariant.yml"; dst = "docker-compose.yml" }
    @{src = "$($ghucSc).env"; dst = ".env" ; skip = $true }
    @{src = "$($ghucSc)Clean-Data.ps1"; dst = "Clean-Data.ps1" }
    @{src = "$($ghuc)Set-LicenseEnvironmentVariable.ps1"; dst = "Set-LicenseEnvironmentVariable.ps1" }    
)

## Data folder creation
$foldersToCreate = @(
    @{src = "./data/cd/" },
    @{src = "./data/cm/" }
    @{src = "./data/commerce-authoring/" }
    @{src = "./data/commerce-minions/" }
    @{src = "./data/commerce-ops/" }
    @{src = "./data/commerce-shops/" }
    @{src = "./data/creativeexchange/" }
    @{src = "./data/identity/" }
    @{src = "./data/solr/" }
    @{src = "./data/sql/" }
    @{src = "./data/xconnect-automationengine/" }
    @{src = "./data/xconnect-indexworker" }
    @{src = "./data/xconnect-processingengine/" }
    @{src = "./data/xconnect/" }
    @{src = "./src/" }
)

$foldersToCreate | ForEach-Object { 
    New-Item -path $_.src -ItemType Directory -ErrorAction Ignore
}

$envFile = ".env";
## SETUP 
$filesToDownload | ForEach-Object { 
    #Add filecheck
    if ($_.skip -eq $true) {
        if (!( Test-Path $_.dst)) {
            Write-Host "Dowloading $($_.src)"
            Invoke-WebRequest $_.src -UseBasicParsing -OutFile $_.dst
        }
    }
    else {
        Write-Host "Dowloading $($_.src)"
        Invoke-WebRequest $_.src -UseBasicParsing -OutFile $_.dst
    }
    
}

## CONFIGURE ENVIRONMENT
if (!((get-content $envFile) -match "REGISTRY=[a-z]+")) {
    $registery = Read-Host "What is your Azure Registry?:"
    ((get-content $envFile ) -replace "REGISTRY=", "REGISTRY=$registery") | set-content $envFile
}

if (!((get-content $envFile) -match "SITECORE_VERSION=[0-9.]+")) {
    ((get-content $envFile ) -replace "SITECORE_VERSION=", "SITECORE_VERSION=$scVersion") | set-content $envFile
}

if ($null -eq $Env:SITECORE_LICENSE ) {
    $scLicensePath = Get-File -description "Where is your Sitecore license located?"  "Sitecore XML |license.xml"
    .\Set-LicenseEnvironmentVariable.ps1 $scLicensePath -PersistForCurrentUser
}

# Run
if ($null -ne (Get-Process $dockerProcess -ErrorAction Ignore)) {
    docker login
    docker-compose pull
    docker-compose up
}
else {
    Write-Error "Could not start docker-compose, did you install & start docker?"
}

Function Get-File($initialDirectory, $description, $filter) {
    [void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    $dialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        Title            = $description
        InitialDirectory = $initialDirectory
        Filter           = $filter
        FilterIndex      = 1
    }
    [void] $dialog.ShowDialog()
    return $dialog.FileNames
}
