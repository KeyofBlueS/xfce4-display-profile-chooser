# xfce4-display-profile-chooser

# Version:    0.4.0
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/xfce4-display-profile-chooser
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

### DESCRIPTION
With this bash script you can manage Xfce display profiles configured in xfce4-display-settings.
This is useful if you want e.g. to automate stuff by setting profiles within a script or with a keyboard shortcut.
Minimum required version of Xfce is 4.14.

### FEATURES
- Set Xfce display profile (option --set-profile <profile_id>). Pass 'list' as <profile_id> to get a menu where you can choose a profile to set.
Various checks are performed to assure a profile can be applied in first place.
The question 'Would you like to keep this configuration?' will be asked after applying a profile, the previous configuration will be restored within 10 seconds if you not reply to this question (this question can be disabled with option --disable-askkeep).
After a profile is successfully applied, the previous profile will be configured as Fallback profile and the current active profile will be configured as Default profile.

- List all Xfce display profiles. The profile set as /displays/ActiveProfile in Xfconf will be highlighted, the state is 'set; active' if current display/s cofiguration match the ActiveProfile, otherwise is 'set; not active'.

- List verbose will show Xfce display profiles configuration (option --list-verbose). The equivalent xrandr command to set a profile will also be shown, useful if you want to port an Xfce display profile in other desktop environments.

- Remove Xfce display profile or remove single outputs from an Xfce display profile (option --remove-profile <profile_id>). Pass 'list' as <profile_id> to get a menu where you can choose a profile to remove.

- Apply a profile even if there are missing display/s, but only if said display/s are configured as inactive in a Xfce display profile (option --skip-inactive).

- All of these features can be used via command line or with a graphical user interface (option --gui).

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
-s, --set-profile <profile_id>      Set a profile. Pass 'list' as <profile_id> to get a menu
                                                   where you can choose a profile to set.
-l, --list-profiles                 Show profiles list.
-v, --list-verbose                  Show profiles list with additional info.
-d, --list-default                  Show Default profile in profiles list.
-f, --list-fallback                 Show Fallback profile in profiles list.
-r, --remove-profile <profile_id>   Remove a profile. Pass 'list' as <profile_id> to get a menu
                                                      where you can choose a profile to remove.
-k, --skip-inactive                 Skip check on outputs configured as inactive.
-a, --disable-askkeep               Disable <Would you like to keep this configuration?> question.
-g, --gui                           Start with a graphical user interface.
-h, --help                          Show this help.
```
