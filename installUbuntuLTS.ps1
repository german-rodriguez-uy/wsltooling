Param (
[Parameter(Mandatory=$True)][ValidateNotNull()][string]$wslName,
[Parameter(Mandatory=$True)][ValidateNotNull()][string]$username,
[Parameter(Mandatory=$True)][ValidateNotNull()][string]$installAllSoftware
)

# create staging directory if it does not exists
if (-Not (Test-Path -Path .\staging)) { $dir = mkdir .\staging }

#Makes file download much faster
$ProgressPreference = 'SilentlyContinue'

#see https://github.com/microsoft/WSL/issues/4607 wsl output encoding issue
$console = ([console]::OutputEncoding)
[console]::OutputEncoding = New-Object System.Text.UnicodeEncoding
if ((wsl -l -v) -match 'wsl-vpnkit') { $vpnkitInstalled=$true}else{ $vpnkitInstalled=$false}
[console]::OutputEncoding = $console

echo $vpnkitInstalled
if ($vpnkitInstalled -ieq $false) {
	echo "Downloading distribution for wsl-vpnkit..."
	Invoke-WebRequest https://github.com/sakai135/wsl-vpnkit/releases/download/v0.3.2/wsl-vpnkit.tar.gz -OutFile .\staging\wsl-vpnkit.tar.gz
	echo "Done."

	echo "Importing distribution into wsl..."
	wsl --import wsl-vpnkit $env:USERPROFILE\wsl-vpnkit .\staging\wsl-vpnkit.tar.gz --version 2
}else{
	echo "wsl-vpnkit already installed, skipping."
}
echo "Starting wsl-vpnkit..."
wsl.exe -d wsl-vpnkit service wsl-vpnkit start

echo "Downloading dev distribution..."
Invoke-WebRequest https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64-wsl.rootfs.tar.gz -OutFile .\staging\ubuntuLTS.tar.gz
echo "Done."

echo "Importing distribution into wsl..."
wsl --import $wslName $env:USERPROFILE\$wslName .\staging\ubuntuLTS.tar.gz
echo "Done.."
#Remove-Item  .\staging\ubuntuLTS.tar.gz

echo "Starting distribution update..."
wsl -d $wslName -u root bash -ic "apt update; apt upgrade -y"

echo "Configuring user $username..."
# create your user and add it to sudoers
wsl -d $wslName -u root bash -ic "./scripts/config/system/createUser.sh $username ubuntu"

# ensure WSL Distro is restarted when first used with user account
wsl -t $wslName

if ($installAllSoftware -ieq $true) {
	echo "Starting devoloper software install..."
    wsl -d $wslName -u root bash -ic "./scripts/config/system/sudoNoPasswd.sh $username"
    wsl -d $wslName -u root bash -ic ./scripts/install/installBasePackages.sh
    wsl -d $wslName -u $username bash -ic ./scripts/install/installAllSoftware.sh
    wsl -d $wslName -u root bash -ic "./scripts/config/system/sudoWithPasswd.sh $username"
}
echo "Script done.."