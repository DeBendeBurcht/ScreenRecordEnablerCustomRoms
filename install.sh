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

# Set what you want to display when installing your module
print_modname() {
  ui_print "*******************************"
  ui_print "   Screen Recorder 720p Fix   "
  ui_print "   Thanks for trying my first Magisk module  "
  ui_print "*******************************"
}

# Function to backup the original file
backup_file() {
  ORIGINAL_FILE="$1"
  BACKUP_FILE="${ORIGINAL_FILE}.bak"
  
  if [ -f "$ORIGINAL_FILE" ]; then
    ui_print "- Backing up original file to $BACKUP_FILE"
    if cp "$ORIGINAL_FILE" "$BACKUP_FILE"; then
      ui_print "- Successfully backed up original file to $BACKUP_FILE"
    else
      abort "Failed to back up original file to $BACKUP_FILE"
    fi
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
    "/system/etc/media_profiles.xml"        # The original XML file to be backed up
    "/system/etc/media_profiles_V1_0.dtd"   # The original DTD file to be backed up
  )

  # Backup original files
  for FILE in "${ORIGINAL_FILES[@]}"; do
    backup_file "$FILE"
  done

  # Replace the original files with the new ones from the module
  ui_print "- Replacing original media_profiles.xml with new file"
  if cp "$MODPATH/system/etc/media_profiles.xml" "/system/etc/media_profiles.xml"; then
    ui_print "- Successfully replaced the original media_profiles.xml."
  else
    abort "Failed to replace the original media_profiles.xml."
  fi

  ui_print "- Replacing original media_profiles_V1_0.dtd with new file"
  if cp "$MODPATH/system/etc/media_profiles_V1_0.dtd" "/system/etc/media_profiles_V1_0.dtd"; then
    ui_print "- Successfully replaced the original media_profiles_V1_0.dtd."
  else
    abort "Failed to replace the original media_profiles_V1_0.dtd."
  fi

  custom_variables
  api_check
  
  # Set permissions for installed files
  set_permissions

  ui_print "- Module installation completed successfully."
}

# Restore the original file from backup
restore_file() {
  BACKUP_FILE="$1"
  
  if [ -f "$BACKUP_FILE" ]; then
    ORIGINAL_FILE="${BACKUP_FILE%.bak}"  # Remove the .bak extension to get the original filename
    ui_print "- Restoring original file from $BACKUP_FILE"
    if mv "$BACKUP_FILE" "$ORIGINAL_FILE"; then
      ui_print "- Successfully restored original file to $ORIGINAL_FILE"
    else
      abort "Failed to restore original file from $BACKUP_FILE"
    fi
  else
    ui_print "- Backup file not found, skipping restore"
  fi
}

# Function called when the module is uninstalled
on_uninstall() {
  # Define the backup files to restore
  BACKUP_FILES=(
    "/system/etc/media_profiles.xml.bak"           # The backup XML file to restore
    "/system/etc/media_profiles_V1_0.dtd.bak"      # The backup DTD file to restore
  )

  # Restore original files from backup
  for BACKUP in "${BACKUP_FILES[@]}"; do
    restore_file "$BACKUP"
  done
}

# Only some special files require specific permissions
set_permissions() {
  set_perm_recursive $MODPATH 0 0 0755 0644
}

custom_variables() {
  if [ -f vendor/build.prop ]; then 
    BUILDS="/system/build.prop vendor/build.prop"
  else 
    BUILDS="/system/build.prop"
  fi
}

# This function allows installation for API levels that match the requisites
api_check() {
  if [ "$API" -ge 31 ]; then
    return
  else
    abort "This module is only for devices running Android 12 or higher."
  fi
}

