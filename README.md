# osint-installer
Script installer (and uninstaller) for git sources OSINT apps. PFM_3.1

## Getting Started
Just clone this project and execute osint_installer.sh or osint_uninstaller.sh with superuser privileges.

By default all the apps are installed under the path `/opt`

osint_uninstaller.sh can receive the *purge* parameter, that remove all dependencies installed previously with osint_installer.sh. Use it carefully, some of them could be shared dependencies.

### Prerequisites
- *git* (obviously).
- *python 2* and *python 3* with **pip**, to download and use the installed apps.
- *whiptail* to show the menu. Installed by default in most of Linux distros.

## Expand me!
osint-installer is an easily extensible script, based on the folder *apps* hierarchy. If you want to add any app to the installer just create a new subfolder with the app name.

### App structure
The app will be shown in the menu with the same name as the app folder.

#### Root files
- *giturl* : contains the app git repository link. This is the only **mandatory** file
- *description.txt* : description to show in installer menu next to the app name.

#### Subfolders
- *Dependencies*
   - *requirements.txt* : [requirements pip file](https://pip.pypa.io/en/stable/user_guide/#requirements-files) for python apps. If it exists prevail over requirements file downloaded from git.
   - *debs.txt* : apps to install with APT package handling utility. One per line.
- *Launcher*
  - *any.desktop* : [desktop file format](https://developer.gnome.org/integration-guide/stable/desktop-files.html.en) to create an entry in OS applications menu.
- *Icon*
  - *any.png* : icon image to show in OS applications menu. It must be referenced in *any.desktop* file (Icon=)
 
 -----
 Whatever, the best way to add a new app is having a look to an already existing app. :smile:
