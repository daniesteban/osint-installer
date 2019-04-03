#!/usr/bin/env bash
#
# Remove apps installed with osint_installer

cd "$(dirname "$0")" || exit 1
source "./globals"   || { echo $(tput setaf 1)"File 'globals' is missing"; exit 2; }
test $(id -u) -eq 0  || { echo $(tput setaf 1)"Run me as admin"$(tput sgr0); exit 3; }
if [ "$1" = "purge" ]; then
    PURGE=true
else
    PURGE=false
fi


# Create a dynamic menu with the folder 'apps' hierarchy
show_menu()
{
    params=(--title "OSINT Uninstaller")
    params+=(--ok-button "Uninstall")
    params+=(--cancel-button "Exit")
    params+=(--separate-output)
    checklist=(--checklist "Select apps to uninstall:" 0 0 0)

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

# Uninstall selected apps from INSTALL_PATH/<app_name>
uninstall_apps()
{
{
    # Calculate step gauge progress
    step=$(((( 100 / $(echo $app_selection | wc -w) ))/5))
    percent=0
    for app in $app_selection; do
        echo -e "\n--> Begin $app uninstallation <--" >> "$LOGFILE"
        _app_path=apps/$app
        _app_install_path=$INSTALL_PATH/$(echo "$app" | tr '[:upper:]' '[:lower:]')
        echo -e "    Uninstall from $_app_install_path" >> "$LOGFILE"

        (( percent+=step ))
        echo -e "XXX\n$percent\nUninstalling $app\nXXX"
        # Only remove dependencies if user wants. Dangerous!!!
        if $PURGE; then
            (( percent+=step ))
            echo $percent # Update gauge
            # DEBIAN dependencies uninstallation
            if [ -f "$_app_path"/dependencies/debs.list ]; then
                xargs --arg-file="$_app_path"/dependencies/debs.list apt-get remove -y >/dev/null 2>&1
                retcode=$?
                if [[ $retcode -ne 0 ]]; then
                    echo -e "    WARNING error $retcode uninstalling debian dependencies" >> "$LOGFILE"
                else
                    echo -e "    Debian dependencies uninstalled" >> "$LOGFILE"
                fi
            fi

            (( percent+=step ))
            echo $percent # Update gauge
            # PYTHON dependencies uninstallation
            if [ -f "$_app_install_path"/requirements.txt ]; then
                if grep -qi python3 "$_app_install_path"/requirements.txt; then
                    cmd_pip=pip3
                elif grep -qi python2 "$_app_install_path"/requirements.txt; then
                    cmd_pip=pip2
                else # not explicit -> default pip
                    cmd_pip=pip
                fi
                $cmd_pip uninstall -y -r "$_app_install_path"/requirements.txt >/dev/null 2>&1
                retcode=$?
                if [[ $retcode -ne 0 ]]; then
                    echo -e "    WARNING error $retcode uninstalling python dependencies" >> "$LOGFILE"
                else
                    echo -e "    Python dependencies uninstalled using $cmd_pip" >> "$LOGFILE"
                fi
            fi
        fi

        (( percent+=step ))
        echo $percent # Update gauge
        # Remove installation
        if [ -d "$_app_install_path" ]; then
            rm -rf "$_app_install_path"
            echo -e "    $app removed from $_app_install_path" >> "$LOGFILE" 
        else
            echo -e "    ERROR installation directory not found ($_app_install_path). Nothing to do" >> "$LOGFILE"
            continue
        fi

        (( percent+=step ))
        echo $percent # Update gauge
        # Remove menu shortcut
        dfile=$(ls "$_app_path"/launcher/)
        if [ -f "$MENU_PATH"/"$dfile" ]; then
            rm -f "$MENU_PATH"/"$dfile"
            echo -e "    Removed shortcut from applications menu" >> "$LOGFILE"
        else
            echo -e "    WARNING shortcut $file not found in $MENU_PATH" >> "$LOGFILE"
        fi
    done
    echo -e "XXX\n100\nUninstallation complete\nXXX"
    sleep 3
} | (whiptail --title "Uninstallation progress" --gauge "Please wait" 6 50 0) 
}


# MAIN
show_menu
[ -z "$app_selection" ] || uninstall_apps
if [ -f "$LOGFILE" ]; then
    printf "\n---\nLog result saved in %s:\n" "$LOGFILE" >> "$LOGFILE"
    whiptail --scrolltext --title "Uninstallation report" --textbox "$LOGFILE" 0 0
fi
exit 0
