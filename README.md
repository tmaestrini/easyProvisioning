# easyProvisioning – resource provisioning made as easy as possible
*easyProvisioning* offers a quick and easy way to provision site resources and a range of predefined assets in SharePoint Online (SPO). By defining a YAML template that contains all the information about the desired site resources, this method is both a straightforward approach to provisioning and also serves as documentation for the provisioned resources.

Under the hood, the provisioning engine is powered by the [PnP.Powershell](https://pnp.github.io/powershell/) module and the [PnPProvisioning concept](https://github.com/pnp/PnP-Provisioning-Schema). This provides us with a powerful toolset for setting up and managing all resources that need to be provisioned within M365.

Give it a try – I'm sure you will have fun! 💪

👉 SPO is currently the only targeted service in M365 – but other services 
will follow asap. Any contributors are welcome! 🙌

## Installation
```powershell
Install-Module -Name powershell-yaml -Scope CurrentUser
Install-Module -Name PnP.PowerShell -RequiredVersion 2.2.0 -Scope CurrentUser
```


## Usage
### Generate SharePoint structure
The resource provisioning generally follows the structure that is defined in the *template file* (see section below).
Simply start the provisioning process by importing the `Provisioning.psm1` module and then calling the `Start-Provisioning` command as follows:

```powershell
Import-Module .\src\Provisioning.psm1 -Force
Start-Provisioning -TemplateName "standard.yml" #-KeepConnectionsAlive

# To test the "consistency" of your template, simply call:
Test-Template -TemplateName "standard.yml"
```

The resource provisioning is idempotent; there are no side effects if you start the process multiple times and each defined resource or setting is only provisioned once.


## Template file
To get your resources provisioned, just write them down in one single YAML file with the
following structure (assuming the file is referenced as `standard.yml` in the usage example above):

```yaml
Tenant: <your tenant name>

# Sharepoint Specific Settings
SharePoint:
  TenantId: <the SharePoint tenant id>
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
        Site Admins:  # optional
        IsHub: true  # optional
        ConnectedHubsite:  # optional
        HomepageLayout: Article # optional; set to 'Home', 'Article' or 'SingleWebPartAppPage'
        Provisioning Template:  # optional; reference any PnP Site Template from your local machine
        # the content structure (aka assets) of your site
        Content:
          # creates a standard document library
          - DocumentLibrary: 
              Title: One
              OnQuickLaunch: True # optional; places a link in the quick launch navigation
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
    
    # define the next sites (as many sites as you like)...
    # - Two: ...
```