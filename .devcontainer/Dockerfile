# Select Base Image for Docker
# Image 'lts-7.2-debian-11' used for Support on Windows and Mac M1 Platform
FROM mcr.microsoft.com/powershell:lts-7.2-debian-11

# Install 'xdg-utils' to support Interactive Logons
RUN apt-get update
RUN apt-get install xdg-utils -y

# Install Powershell Moduels to Support Installation
RUN pwsh -c "Install-Module -Force -Scope CurrentUser -Verbose -Name powershell-yaml"
RUN pwsh -c "Install-Module -Force -Scope CurrentUser -Verbose -Name PnP.Powershell -RequiredVersion 2.4.0"

# Overwrites Default Shell to PowerShell
SHELL [ "pwsh", "-c" ]
