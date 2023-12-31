# easyProvisioning – resource provisioning made as easy as possible
*easyProvisioning* offers a quick and easy way to provision site resources and a range of predefined assets in SharePoint Online (SPO). By defining a YAML template that contains all the information about the desired site resources, this method is both a straightforward approach to provisioning and also serves as documentation for the provisioned resources.

Under the hood, the provisioning engine is powered by the [PnP.Powershell](https://pnp.github.io/powershell/) module and the [PnPProvisioning concept](https://github.com/pnp/PnP-Provisioning-Schema). This provides us with a powerful toolset for setting up and managing all resources that need to be provisioned within M365 – driven by the power of PowerShell 😃.

Give it a try – I'm sure you will like it! 💪

👉 For now, SPO is currently the only targeted service in M365 – but other services will follow asap.<br>
Any contributors are welcome! 🙌


## Dependencies
![PnP.PowerShell](https://img.shields.io/badge/PnP.Powershell-2.2.0-green.svg) 


## Applies to
- [SharePoint Online](https://learn.microsoft.com/en-us/office365/servicedescriptions/sharepoint-online-service-description/sharepoint-online-service-description)
- [Microsoft 365 tenant](https://docs.microsoft.com/en-us/sharepoint/dev/spfx/set-up-your-developer-tenant)

> Get your own free development tenant by subscribing to [Microsoft 365 developer program](http://aka.ms/o365devprogram)


## Solution

| Solution         | Author(s)                                                                                   |
| ---------------- | ------------------------------------------------------------------------------------------- |
| easyProvisioning | Tobias Maestrini (bee365 / adesso Schweiz ag) [@tmaestrini](https://twitter.com/tmaestrini) |


## Version history

| Version | Date           | Comments        |
| ------- | :------------- | :-------------- |
| 1.0     | November, 2023 | Initial release |


## Disclaimer

**THIS CODE IS PROVIDED _AS IS_ WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**

---

## Minimal path to awesome
### Installation
```powershell
Install-Module -Name powershell-yaml -Scope CurrentUser
Install-Module -Name PnP.PowerShell -RequiredVersion 2.2.0 -Scope CurrentUser
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

The resource provisioning process is idempotent; each defined resource or setting is only provisioned once. You can start the sync process as many times you want without expecting any side effects!

### Create a folder structure for a given site
You can define any folder structure in a given site. While running the regular provisioning setup (see paragraph «Generate SharePoint structure»), a given folder structure will be created along its optional `Folder` definition in the site scope.

Although the provisioning process for creating the SharePoint structure includes this (if defined), the function can also be executed within a desired site in a separate step. Make sure establish a connection to the destination site before you start the generation of the folder structure:

```powershell
$siteConn = Connect-PnPOnline "https://yourtenant.sharepoint.com/sites/site" -Interactive -ReturnConnection
Import-Module .\src\Provisioning.psm1 -Force
Add-FolderStructureToLibrary -TemplateName "standard.yml" -siteConnection $siteConn
```
The resource provisioning process is idempotent; each defined folder is only provisioned once. You can run the process as many times you want without expecting any side effects!



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
    - One:
        # the relative site url
        Url: /sites/TestOne
        # set to 'Communication', 'Team' or 'SPOTeam' (Modern Team Site w/o M365 Group)
        Type: Communication 
        # only needed when type is 'Communication'; set it to 'Blank', 'Showcase' or 'Topic'
        Template: Blank 
        Site Admins: # optional
        Lcid: 1031  # optional; set to 1031 by default
        HomepageLayout: Article # optional; set to 'Home' (default), 'Article' or 'SingleWebPartAppPage'
        IsHub: true  # optional
        ConnectedHubsite:  # optional
        CopyHubNavigation: # optional; set the relative path to the hub site from where the navigation structure will be copied
        Provisioning Template:  # optional; reference any PnP Site Template from your local machine
        # the content structure (aka assets) of your site
        Content:
          # creates a standard document library
          - DocumentLibrary: 
              Title: One
              OnQuickLaunch: True # optional; places a link in the quick launch navigation
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

          # creates a generic SPO list
          - List:  
              Title: Three
              OnQuickLaunch: True
          # creates a calendar
          - EventsList:
              Title: Four
          # creates a specific media library to store media assets
          - MediaLibrary:
              Title: Five
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
