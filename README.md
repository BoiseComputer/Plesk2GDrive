# Plesk2GDrive
*This project is on hold until a working Google Drive for Linux command line is developed.*
####Plesk2GDrive: Simple to use Plesk Backup Script for Google Drive
```
Usage: plesk2gdrive-backup.sh [-c day : Set day of week] [-d ID : Delete specific Backup] [-v : Verify settings] [-r : Performs Backup] [-l : Lists Backups] [-h : Detailed Help Page]
 -c  : Choose day of the week to manage.
            Example : -c Sunday
 -d   : Delete specific backup file. Use -v to find ID of file on Google Drive.
            Example : -d 0B3oLpdWVoonmemtxQklFYXBTZHM
 -v       : Verifies settings and file locations. Also lists backups for selected day.
 -r       : Performs backup. Must be set for backup to be performed and uploaded.
 -l       : Lists backups for specified day.
 -h       : Displays this help page.
```
Filenames will resemble: Saturday.tar, Monday.tar, etc.
Backups are placed in a folder named “plesk2gdrive” on Google Drive.

- A backup file will not be created unless you use the **-r** option.
- Run the **-v** option to verify your configuration is correct before attempting to use the -r option.
- Make sure you verify line **#38** to ensure it is compatible with your system configuration. 
- Running the -v option will download any missing files and create a plesk2gdrive folder on Google Drive.
