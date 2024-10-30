#!/system/bin/sh
# Magisk Module Uninstaller Script

##########################################################################################
# Function Callbacks
# The following functions will be called by the installation framework for uninstallation.
##########################################################################################

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

  # You can add additional cleanup tasks if necessary
  ui_print "- Module uninstallation completed successfully."
}

# Call the uninstallation function
on_uninstall
