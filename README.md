# AdvanceKextUpdater
Keep your kexts up-to-date all the time starting from macOS 10.7

**NOTE:** This project is still in progress.

## Introduction
AdvanceKextUpdater is a huge project similar to a GUI based package manager, consisting of an App and a database.

  The database (`kext_db` branch of this project) consists of a bunch of folders where configurations with additional
  information is kept. The `catalog.json` is the file that contains link to these folders or remote URLs (if the
  configuration file is handled remotely by a repo or just a website).

  The app parses the `catalog.json` file along with the configuration to determine what to do with a given Kext.
  
This style makes this project wholly separate from any other project and can be compared to `composer.json` project
which is used by many PHP devs to keep their external libraries up-to-date.

## Features
The final release will contain the following features. Already implemented features are marked as `Done`.

- Search, download, install, update kext(s) right from the App
- Not only install a kext but also its dependencies and remove all the potential conflicts
- Check for new updates on startup
- Ability to update kext(s) automatically (with certain restrictions, of course)
- (`Done`) View all information about the kext, they includes:
  * Short description
  * Guide (if available) which may be useful for some kext
  * Changes in the new version of the kext
  * License
  * Authors (Yes, they should be recognize properly)
  * Requirements
  * Conflicts
  * Replaced by (if the kext is obsolete and replaced by another kext)
  * The macOS version prior to which the kext is available, etc.
- (`Done`) View suggested Kext(s)
- (`Done`) Ability to repair permissions, update kernel cache

In this app, you can only install/update a kext if all the criterias presents in the config file are matched. If they
don't match, based on the config file, we can either revoke the installation or warn you of the potential harm that might
have happened to your system.

Have more ideas? [Create a new feature request](https://github.com/MuntashirAkon/AdvanceKextUpdater/issues/new).

## Contributions
You're welcome to contribute to this project. You can contribute to the [dev](https://github.com/MuntashirAkon/AdvanceKextUpdater/tree/dev)
branch or the [kext_db](https://github.com/MuntashirAkon/AdvanceKextUpdater/tree/kext_db) branch of the project.
It crucial to keep the database up-to-date and to do that some clever idea will be implemented in future, but for now
they have to be updated manually. So, contributions are necessary on the kext developers part.

If you're interested in contributing in the `kext_db` branch only, you should skip cloning the other branches. Here's a hint
if you forgot how to do this:
```sh
git clone -b kext_db https://github.com/MuntashirAkon/AdvanceKextUpdater.git
```

## License
GPLv3.0

## Donations
I don't accept any donations.

## Credits
- [Apple](https://apple.com) for their wonderful OS
- [@phpdev32](https://sourceforge.net/u/phpdev32) for 
  [DPCIManager](https://github.com/MuntashirAkon/DPCIManager)'s initial source code

## Third-party Libraries
- [MMMarkdown](https://github.com/mdiep/MMMarkdown) - For parsing markdown texts
- [github-markdown-css](https://github.com/sindresorhus/github-markdown-css) - For styling parsed markdown texts
- [STPrivilegedTask](https://github.com/sveinbjornt/STPrivilegedTask) - For running task as administrator

## TODO List
- add support for `remote_url`
- install, update, remove a kext
- auto update kext
- add the ability to include `sysctl` key-values in the config.json file 
