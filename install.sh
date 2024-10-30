##########################################################################################
#
# Magisk Module Installer Script
#
##########################################################################################
##########################################################################################
#
# Instructions:
#
# 1. Place your files into system folder (delete the placeholder file)
# 2. Fill in your module's info into module.prop
# 3. Configure and implement callbacks in this file
# 4. If you need boot scripts, add them into common/post-fs-data.sh or common/service.sh
# 5. Add your additional or modified system properties into common/system.prop
#
##########################################################################################

##########################################################################################
# Config Flags
##########################################################################################

# Set to true if you do *NOT* want Magisk to mount
# any files for you. Most modules would NOT want
# to set this flag to true
SKIPMOUNT=false

# Set to true if you need to load system.prop
PROPFILE=false

# Set to true if you need post-fs-data script
POSTFSDATA=false

# Set to true if you need late_start service script
LATESTARTSERVICE=false

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info why you would need this

# Construct your list in the following format
# This is an example
REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here
REPLACE="
"

##########################################################################################
#
# Function Callbacks
#
# The following functions will be called by the installation framework.
# You do not have the ability to modify update-binary, the only way you can customize
# installation is through implementing these functions.
#
# When running your callbacks, the installation framework will make sure the Magisk
# internal busybox path is *PREPENDED* to PATH, so all common commands shall exist.
# Also, it will make sure /data, /system, and /vendor is properly mounted.
#
##########################################################################################
##########################################################################################
#
# The installation framework will export some variables and functions.
# You should use these variables and functions for installation.
#
# ! DO NOT use any Magisk internal paths as those are NOT public API.
# ! DO NOT use other functions in util_functions.sh as they are NOT public API.
# ! Non public APIs are not guaranteed to maintain compatibility between releases.
#
# Available variables:
#
# MAGISK_VER (string): the version string of current installed Magisk
# MAGISK_VER_CODE (int): the version code of current installed Magisk
# BOOTMODE (bool): true if the module is currently installing in Magisk Manager
# MODPATH (path): the path where your module files should be installed
# TMPDIR (path): a place where you can temporarily store files
# ZIPFILE (path): your module's installation zip
# ARCH (string): the architecture of the device. Value is either arm, arm64, x86, or x64
# IS64BIT (bool): true if $ARCH is either arm64 or x64
# API (int): the API level (Android version) of the device
#
# Available functions:
#
# ui_print <msg>
#     print <msg> to console
#     Avoid using 'echo' as it will not display in custom recovery's console
#
# abort <msg>
#     print error message <msg> to console and terminate installation
#     Avoid using 'exit' as it will skip the termination cleanup steps
#
# set_perm <target> <owner> <group> <permission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     this function is a shorthand for the following commands
#       chown owner.group target
#       chmod permission target
#       chcon context target
#
# set_perm_recursive <directory> <owner> <group> <dirpermission> <filepermission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     for all files in <directory>, it will call:
#       set_perm file owner group filepermission context
#     for all directories in <directory> (including itself), it will call:
#       set_perm dir owner group dirpermission context
#
##########################################################################################
##########################################################################################
# If you need boot scripts, DO NOT use general boot scripts (post-fs-data.d/service.d)
# ONLY use module scripts as it respects the module status (remove/disable) and is
# guaranteed to maintain the same behavior in future Magisk releases.
# Enable boot scripts by setting the flags in the config section above.
##########################################################################################

# Set what you want to display when installing your module

print_modname() {
  ui_print "*******************************"
  ui_print "   Screen Recorder 720p Fix   "
  ui_print "*******************************"
}

# Function to backup the original file
backup_file() {
  ORIGINAL_FILE="$1"
  BACKUP_FILE="${ORIGINAL_FILE}.bak"
  
  # Check if the original file exists
  if [ -f "$ORIGINAL_FILE" ]; then
    ui_print "- Backing up original file to $BACKUP_FILE"
    cp "$ORIGINAL_FILE" "$BACKUP_FILE"
  else
    ui_print "- Original file not found, skipping backup"
  fi
}

# Copy/extract your module files into $MODPATH in on_install.

on_install() {
  ui_print "- Extracting module files"
  unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2

  # Define the original file paths you wish to back up
  ORIGINAL_FILES=(
    "/system/path/to/original/file"  # Replace this with actual paths
    # Add more files as needed
  )

  # Backup original files
  for FILE in "${ORIGINAL_FILES[@]}"; do
    backup_file "$FILE"
  done
  
  custom_variables
  api_check
}

# Restore the original file from backup
restore_file() {
  BACKUP_FILE="$1"
  
  if [ -f "$BACKUP_FILE" ]; then
    ORIGINAL_FILE="${BACKUP_FILE%.bak}"  # Remove the .bak extension to get the original filename
    ui_print "- Restoring original file from $BACKUP_FILE"
    mv "$BACKUP_FILE" "$ORIGINAL_FILE"
  else
    ui_print "- Backup file not found, skipping restore"
  fi
}

# Function called when the module is uninstalled
on_uninstall() {
  # Define the backup files to restore
  BACKUP_FILES=(
    "/system/path/to/original/file.bak"  # Replace this with actual paths
    # Add more backup files as needed
  )

  # Restore original files from backup
  for BACKUP in "${BACKUP_FILES[@]}"; do
    restore_file "$BACKUP"
  done
}

# Only some special files require specific permissions
# This function will be called after on_install is done
set_permissions() {
  set_perm_recursive $MODPATH 0 0 0755 0644
}

  # Here are some examples:
  # set_perm_recursive  $MODPATH/system/lib       0     0       0755      0644
  # set_perm  $MODPATH/system/bin/app_process32   0     2000    0755      u:object_r:zygote_exec:s0
  # set_perm  $MODPATH/system/bin/dex2oat         0     2000    0755      u:object_r:dex2oat_exec:s0
  # set_perm  $MODPATH/system/lib/libart.so       0     0       0644
}

# You can add more functions to assist your custom script code

custom_variables() {
  if [ -f vendor/build.prop ]; then 
    BUILDS="/system/build.prop vendor/build.prop"
  else 
    BUILDS="/system/build.prop"
  fi
}

# this function allows installation just with API level that matches the requisites

api_check() {
  if [ "$API" -eq 25 ] || [ "$API" -eq 24 ]; then
    # Valid API levels for installation
    return
  else
    abort "This module is only for devices running Nougat"
  fi
}
