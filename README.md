# UnityProjectsArchiveTool

A PowerShell CLI tool for managing multiple Unity projects in a single workspace.

The tool helps maintain large collections of Unity projects by providing automated scanning, cleanup, script backups, and final asset archiving into compressed packages.

It is designed for developers who maintain many prototype projects, experiments, or archived versions and want a fast way to reduce disk usage while preserving important assets.

---

## Features

### Project Discovery
Automatically detects Unity projects inside the tool directory.

A folder is considered a Unity project if it contains an `Assets` directory.

---

### Project Dashboard
Shows an overview of detected projects including:

- project name
- number of scripts
- last modified time
- estimated cleanup size
- total workspace statistics

---

### Project Scanning
Scans all Unity projects and gathers statistics about:

- scripts
- project size
- temporary build folders
- potential cleanup targets

---

### Cleanup Tool
Removes common Unity-generated folders to free disk space:
