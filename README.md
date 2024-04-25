# easyProvisioning – resource provisioning made as easy as possible
*easyProvisioning* offers a quick and easy way to provision site resources and a range of predefined assets in SharePoint Online (SPO). By defining a YAML template that contains all the information about the desired site resources, this method is both a straightforward approach to provisioning and also serves as documentation for the provisioned resources.

Under the hood, the provisioning engine is powered by the [PnP.Powershell](https://pnp.github.io/powershell/) module and the [PnPProvisioning concept](https://github.com/pnp/PnP-Provisioning-Schema). This provides us with a powerful toolset for setting up and managing all resources that need to be provisioned within M365 – driven by the power of PowerShell 😃.

Give it a try – I'm sure you will like it! 💪

> [!NOTE]
> 👉 For now, SPO is currently the only targeted service in M365 – but other services will follow asap.<br>
> Any contributors are welcome! 🙌


## Dependencies
![PowerShell](https://img.shields.io/badge/Powershell-7.4.1-blue.svg) 
![PnP.PowerShell](https://img.shields.io/badge/PnP.Powershell-2.4.0-blue.svg)
![Microsoft.Graph](https://img.shields.io/badge/powershell--yaml-0.4.7-blue.svg) 


## Applies to
- [SharePoint Online](https://learn.microsoft.com/en-us/office365/servicedescriptions/sharepoint-online-service-description/sharepoint-online-service-description)
- [Microsoft 365 tenant](https://docs.microsoft.com/en-us/sharepoint/dev/spfx/set-up-your-developer-tenant)

> Get your own free development tenant by subscribing to [Microsoft 365 developer program](http://aka.ms/o365devprogram)


## Solution

| Solution         | Author(s)                                                                                   |
| ---------------- | ------------------------------------------------------------------------------------------- |
| easyProvisioning | Tobias Maestrini [@tmaestrini](https://twitter.com/tmaestrini) |


## Version history

| Version | Date           | Comments        |
| ------- | :------------- | :-------------- |
| 1.0     | November, 2023 | Initial release |
| 1.1     | March, 2024    | Updated provisioning schema for tenants |
| 1.1.1   | April, 2024    | Add reference templates integration |


## Disclaimer

**THIS CODE IS PROVIDED _AS IS_ WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**

---

## Minimal path to awesome
### Installation
```powershell
Install-Module -Name powershell-yaml -Scope CurrentUser
Install-Module -Name PnP.PowerShell -RequiredVersion 2.4.0 -Scope CurrentUser
```

### Generate SharePoint structure
The resource provisioning generally follows the structure that is defined by the YAML structure within the *template file* (for reference: see section below).
Simply start the provisioning process by importing the `Provisioning.psm1` module and then calling the `Start-Provisioning` command as follows:

```powershell
Import-Module .\src\Provisioning.psm1 -Force
Start-Provisioning -TemplateName "standard.yml" #-KeepConnectionsAlive

# To test the "consistency" of your template, simply call:
Test-Template -TemplateName "standard.yml"
```

The resource provisioning process is idempotent; each defined resource or setting is only provisioned once. You can start the provisioning process as many times you want without expecting any side effects!

### Sync hub navigation from template site
You can sync any given hub navigation to any given site. Although the provisioning process for creating the SharePoint structure includes this (if defined), the function can also be executed again in a separate step.

The hub navigation synchronization copies an existing navigation structure from a relative site url (e.g. `/sites/IntranetHome`) that is specified in the template attribute `CopyHubNavigation` in the *template file* (see section below) and applies it to the target site (that is the site where the template attribute `CopyHubNavigation` was defined). Just make sure that the target site has a proper hub navigation and the relative path to the site url exists. This is really nice – it leads to a consistent navigation experience on all intranet sites!

Simply start the provisioning process by importing the `Provisioning.psm1` module (if not already done so!) and then calling the `Sync-Hubnavigation` command as follows:

```powershell
Import-Module .\src\Provisioning.psm1 -Force
Sync-Hubnavigation -TemplateName "standard.yml"
```

> [!NOTE]
>  The resource provisioning process is idempotent; each defined resource or setting is only provisioned once. You can start the sync process as many times you want without expecting any side effects!


### Create a folder structure for a given site
You can define any folder structure in a given site. While running the regular provisioning setup (see paragraph «Generate SharePoint structure»), a given folder structure will be created along its optional `Folder` definition in the site scope.

> [!WARNING]
> Before provisioning any specific folder structure, a connection to the according site (target site) must be established.
> The site (target site) must match the site identifier in the content structure of the tenant template!


Although the provisioning process for creating the SharePoint structure includes this (if defined), the function can also be executed within a desired site in a separate step. 
Make sure to establish a connection to the destination site before you start the generation of the folder structure:

```powershell
$siteConn = Connect-PnPOnline "https://yourtenant.sharepoint.com/sites/site" -Interactive -ReturnConnection
Import-Module .\src\Provisioning.psm1 -Force
Add-FolderStructureToLibrary -TemplateName "standard.yml" -siteConnection $siteConn
```
> [!NOTE]
> The resource provisioning process is idempotent; each defined folder is only provisioned once. You can run the process as many times you want without expecting any side effects!



## The template file (YAML)
To get your resources provisioned, just write down the structure in one single YAML file.
All you have to do is to make sure that your YAML file implements the following schema.

Assuming the file is referenced as `standard.yml` (in the usage example above) and exists under the path `/templates`),
a new SharePoint Communication Site named `One` will be created:

```yaml
Tenant: <your tenant name> # name can be set according to your needs

# Sharepoint Specific Settings
SharePoint:
  TenantId: <the SharePoint tenant name> # the name of the Sharepoint tenant (e.g. contoso)
  AdminUpn: <the admin's UPN>

  Structure:
    # creates a new hub site ('Hub' is the site type; can also be set to 'Site') with the title 'One'
    - Hub: One # declare the type either as 'Site' or 'Hub'
        # the relative site url
      Url: /sites/TestOne
      # set to 'Communication', 'Team' or 'SPOTeam' (Modern Team Site w/o M365 Group)
      Type: Communication 
      # only needed when type is 'Communication'; set it to 'Blank', 'Showcase' or 'Topic'
      Template: Blank 
      Site Admins: # optional
      Lcid: 1031  # optional; set to 1031 by default
      HomepageLayout: Article # optional; set to 'Home' (default), 'Article' or 'SingleWebPartAppPage'
      ConnectedHubsite:  # optional; set the relative path to the parent hub site
      CopyHubNavigation: # optional; set the relative path to the hub site from where the navigation structure will be copied
      Provisioning Template:  # optional; reference any PnP Site Template from your local machine
      # the content structure (aka assets) of your site
      Content:
        # creates a standard document library with title 'One'
        - DocumentLibrary: One
          OnQuickLaunch: True # optional; places a link in the quick launch navigation
          Provisioning Template:  # optional; reference any PnP List Template (and only list template!) from your local machine
          Folders: # optional; generates a folder structure (items are folder names)
            - Alpha:
                - Alpha.One:
                    - Alpha.One.1 [Demo 1]:
                        - One
                - Alpha.Two
                - Alpha.Three
            - Beta:
                - Beta.One
                - Beta.Two:
                    - Beta.Two.1
                    - Beta.Two.2
                    - Beta.Two.3
            - Gamma          

        # creates a standard document library with title 'Three'
        - List: Three
          OnQuickLaunch: True
        # creates a calendar with title 'Four'
        - EventsList: Four
        # creates a specific media library to store media assets with title 'Five'
        - MediaLibrary: Five
          OnQuickLaunch: True
          Folders: # optional; generates a folder structure (items are folder names)
            - Alpha:
                - Alpha.One:
                    - Alpha.One.1 [Demo 1]:
                        - One
                - Alpha.Two
                - Alpha.Three
            - Beta:
                - Beta.One
                - Beta.Two:
                    - Beta.Two.1
                    - Beta.Two.2
                    - Beta.Two.3
            - Gamma          
    # define the next sites (as many sites as you like)...
    # - Two: ...
```

### Integrate sub structures into your tenant template

In order to structure or modularize your tenant structure, you can divide a basic structure into a _main definition template_ and an _extension template_.
Therefore, you simply have to integrate the _extension template_ in the _main definition template_ by referencing the relative path (from the project's root) within the `contains` attribute. 

> [!NOTE]
> The _extension template_ is a fully functional tenant template file (.yml), which could work as a standalone template definition.

Your _main definition template_ must look like this in the first definition rows:

```yaml
Tenant: <your tenant name> # name can be set according to your needs

# optional; set the relative path (to the root) to another settings file which contains provisioning settings that should be applied to this site
Contains: tenants/templates/hr.yml

# further structure omitted
```
The _extension template_ file can contain any structure along your needs. 

> [!NOTE]
> To make use of the _extension template_, make sure that the name of the SharePoint tenant in the _extension template_ matches exactly the tenant's name in the main definition template.

Example structure of the _extension template_:

```yaml
Tenant: <your tenant name> # name can be set according to your needs

# Sharepoint Specific Settings
SharePoint:
  TenantId: <the SharePoint tenant name> # the name of the Sharepoint tenant (e.g. contoso) must match the tenant's name in the main definition template
  AdminUpn: <the admin's UPN>

  Structure:
    - Site: HR One
      Url: /sites/HR-One
      Type: SPOTeam 
      Template: Blank
      ConnectedHubsite: /sites/HR

    - Site: HR Two
      Url: /sites/HR-Two
      Type: SPOTeam 
      Template: Blank
      ConnectedHubsite: /sites/HR

    - Site: HR Three
      Url: /sites/HR-Three
      Type: SPOTeam 
      Template: Blank
      ConnectedHubsite: /sites/HR
```