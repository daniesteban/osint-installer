#!/usr/bin/env bash
#
# Install apps getting them from sites like github

cd "$(dirname "$0")" || exit 1
source "./globals"   || { echo $(tput setaf 1)"File 'globals' is missing"; exit 2; }
test $(id -u) -eq 0  || { echo $(tput setaf 1)"Run me as admin"$(tput sgr0); exit 3; }


# Create a dynamic menu with the folder 'apps' hierarchy
show_menu()
{
    params=(--title "OSINT Installer")
    params+=(--ok-button "Install")
    params+=(--cancel-button "Exit")
    params+=(--separate-output)
    checklist=(--checklist "Select apps to install:" 0 0 0)

    app_list=$(ls apps/)
    for app in $app_list; do
        _app_path=apps/$app
        if [ -f "$_app_path"/description.txt ]; then
            description=$(head -n1 "$_app_path"/description.txt | cut -c 1-50)" "
        else
            description="No description"
        fi
        checklist+=("$app" "$description" OFF)
    done

    app_selection=$(whiptail "${params[@]}"  "${checklist[@]}" 3>&1 1>&2 2>&3)
}

# Install selected apps into INSTALL_PATH/<app_name>
install_apps()
{
{
    # Calculate step gauge progress
    step=$(((( 100 / $(echo $app_selection | wc -w) ))/5))
    percent=0
    for app in $app_selection; do
        echo -e "\n--> Begin $app installation <--" >> "$LOGFILE"
        _app_path=apps/$app
        _app_install_path=$INSTALL_PATH/$(echo "$app" | tr '[:upper:]' '[:lower:]')
        echo -e "    Install to $_app_install_path" >> "$LOGFILE"

        (( percent+=step ))
        echo -e "XXX\n$percent\nInstalling $app\nXXX"
        # Clean previous installations
        if [ -d "$_app_install_path" ]; then
            echo -e "    Removed previous installation" >> "$LOGFILE"
            rm -rf "$_app_install_path"
        fi

        (( percent+=step ))
        echo $percent # Update gauge
        # Download code
        if ! [ -f "$_app_path"/giturl ]; then
            echo -e "    ERROR can't find download url (giturl file)" >> "$LOGFILE"
            continue
        else
            git clone $(cat "$_app_path"/giturl) "$_app_install_path" >/dev/null 2>&1
            retcode=$?
            if [[ $retcode -ne 0 ]]; then
                echo -e "    ERROR $retcode getting code from internet" >> "$LOGFILE"
                rm -rf "$_app_install_path"
                continue
            else
                echo -e "    $app downloaded to $_app_install_path" >> "$LOGFILE" 
            fi
        fi

        (( percent+=step ))
        echo $percent # Update gauge
        # DEBIAN dependencies installation
        if [ -f "$_app_path"/dependencies/debs.list ]; then
            apt-get update >/dev/null 2>&1
            xargs --arg-file="$_app_path"/dependencies/debs.list apt-get install -y >/dev/null 2>&1
            retcode=$?
            if [[ $retcode -ne 0 ]]; then
                echo -e "    WARNING error $retcode installing debian dependencies" >> "$LOGFILE"
            else
                echo -e "    Debian dependencies installed" >> "$LOGFILE"
            fi
        fi

        (( percent+=step ))
        echo $percent # Update gauge
        # PYTHON dependencies installation
        # If exist custom requirements use it over downloaded one
        if [ -f "$_app_path"/dependencies/requirements.txt ]; then
            cp -f "$_app_path"/dependencies/requirements.txt "$_app_install_path"
        fi
        if [ -f "$_app_install_path"/requirements.txt ]; then
            if grep -qi python3 "$_app_install_path"/requirements.txt; then
                cmd_pip=pip3
            elif grep -qi python2 "$_app_install_path"/requirements.txt; then
                cmd_pip=pip2
            else # not explicit -> default pip
                cmd_pip=pip
            fi
            $cmd_pip install --upgrade -r "$_app_install_path"/requirements.txt >/dev/null 2>&1
            retcode=$?
            if [[ $retcode -ne 0 ]]; then
                echo -e "    WARNING error $retcode installing python dependencies" >> "$LOGFILE"
            else
                echo -e "    Python dependencies installed using $cmd_pip" >> "$LOGFILE"
            fi
        fi

        (( percent+=step ))
        echo $percent # Update gauge
        # Create menu shortcut
        if [ -d "$_app_path"/launcher ] && [ -d "$MENU_PATH" ]; then
            cp -f "$_app_path"/launcher/* "$MENU_PATH"
            echo -e "    Created shortcut in applications menu" >> "$LOGFILE"
        fi
        if [ -d "$_app_path"/icon ]; then
            cp -rf "$_app_path"/icon "$_app_install_path"
        fi
    done
    echo -e "XXX\n100\nInstallation complete\nXXX"
    sleep 3
} | (whiptail --title "Installation progress" --gauge "Please wait" 6 50 0) 
}


# MAIN
show_menu
[ -z "$app_selection" ] || install_apps
if [ -f "$LOGFILE" ]; then
    printf "\n---\nLog result saved in %s:\n" "$LOGFILE" >> "$LOGFILE"
    whiptail --scrolltext --title "Installation report" --textbox "$LOGFILE" 0 0
fi
exit 0
