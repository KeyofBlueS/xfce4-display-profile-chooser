# xfce4-display-profile-chooser

# Version:    0.3.6
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/xfce4-display-profile-chooser
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

### DESCRIPTION
With this bash script you can, via command line, list, set and remove already configured display profiles in xfce4-display-settings.
This is useful if you want e.g. to automate stuff by setting profiles within a script or to use a keyboard shortcut.
A graphical user interface is provided with yad.

### TODO
Prevent the application of a profile that contains one or more displays that are not connected, cause it can lead to a misconfiguration. Help is needed, please see https://github.com/KeyofBlueS/xfce4-display-profile-chooser/issues/1. ANYWAY if your display/s are always the same, then this script can be considered reliable.

### INSTALL
```sh
curl -o /tmp/xfce4-display-profile-chooser.sh 'https://raw.githubusercontent.com/KeyofBlueS/xfce4-display-profile-chooser/master/xfce4-display-profile-chooser.sh'
sudo mkdir -p /opt/xfce4-display-profile-chooser/
sudo mv /tmp/xfce4-display-profile-chooser.sh /opt/xfce4-display-profile-chooser/
sudo chown root:root /opt/xfce4-display-profile-chooser/xfce4-display-profile-chooser.sh
sudo chmod 755 /opt/xfce4-display-profile-chooser/xfce4-display-profile-chooser.sh
sudo chmod +x /opt/xfce4-display-profile-chooser/xfce4-display-profile-chooser.sh
sudo ln -s /opt/xfce4-display-profile-chooser/xfce4-display-profile-chooser.sh /usr/local/bin/xfce4-display-profile-chooser
```
### USAGE
```sh
$ xfce4-display-profile-chooser <option> <value>
```
```
Options:
-s, --set-profile <profile_id>      Set a profile
-l, --list-profiles                 Show profiles list
-v, --list-verbose                  Show profiles list with additional info
-d, --list-default                  Show Default profile in profiles list
-f, --list-fallback                 Show Fallback profile in profiles list
-r, --remove-profile <profile_id>   Remove a profile
-k, --skip-inactive                 Skip check on outputs configured as inactive
-a, --disable-askkeep               Disable <Would you like to keep this configuration?> question
-g, --gui                           Start with a graphical user interface
-h, --help                          Show this help
```
