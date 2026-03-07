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

```

Library
Temp
Obj
Logs
UserSettings

```

This can reduce project size dramatically without affecting source assets.

---

### Script Backup
Creates compressed backups of all `Assets/Scripts` folders.

Backups are stored in:

```

ScriptBackups/

```

Each project gets its own timestamped archive.

---

### Final Assets Archive
Creates a final compressed archive containing the `Assets` folders of all projects.

The archive structure:

```

Assets/
ProjectA/
ProjectB/
ProjectC/

```

Certain folders are skipped during archiving to reduce size:

```

Plugins
Extensions
Samples
Scenes
StreamingAssets
ThirdParty

```

After the archive is created, the tool can optionally delete the original project folders.

---

### Automatic Temp Cleanup
On startup the tool automatically removes leftover temporary folders such as:

```

TempBackup
_TempMergedAssets

```

This ensures safe re-runs after interrupted operations.

---

## Requirements

- Windows
- PowerShell 5.1 or PowerShell 7+
- Unity projects stored inside the same root directory as the script

---

## Usage

Place the script in the directory containing your Unity projects:

```

Workspace/
UnityProjectsArchiveTool.ps1
ProjectA/
ProjectB/
ProjectC/

````

Run the script:

```powershell
.\UnityProjectsArchiveTool.ps1
````

---

## Menu

```
1 - Project Dashboard
2 - Scan Projects
3 - Cleanup Projects
4 - Backup Scripts
5 - Final Assets Archive
6 - Exit
```

Press **ESC** at any time to exit the tool.

---

## Example Workflow

Typical project maintenance workflow:

```
1 → View dashboard
3 → Cleanup projects
4 → Backup scripts
5 → Create final archive
```

This allows large Unity project collections to be safely archived while preserving essential assets.

---

## Safety

The tool avoids modifying or deleting project files unless the user confirms the action.

Deletion operations always require confirmation.

---

## Repository Structure

```
UnityProjectsArchiveTool/
│
├─ UnityProjectsArchiveTool.ps1
├─ README.md
└─ ScriptBackups/
```

---

## Possible Future Improvements

| Progress      | Feature                    | Description                                                                     |
| ------------- | -------------------------- | ------------------------------------------------------------------------------- |
| ---**-------- | Parallel Project Scanning  | Scan multiple Unity projects simultaneously to significantly improve speed.     |
| *------------ | Asset Deduplication        | Detect identical assets across projects and store only one copy in the archive. |
| *------------ | Interactive CLI Menu       | Arrow-key navigation with highlighted selections.                               |
| *------------ | Live Progress Bars         | Real-time progress display when scanning or archiving projects.                 |
| *------------ | Disk Usage Visualization   | Show graphical or color-coded disk usage statistics.                            |
| *------------ | Archive Verification       | Verify integrity of created archives after compression.                         |
| *------------ | Config File Support        | Allow customizing ignored folders and cleanup targets via config file.          |
| *------------ | Selective Archiving        | Allow users to choose which projects to archive.                                |
| *------------ | Restore Tool               | Restore archived projects back into full Unity project structure.               |
| *------------ | Logging System             | Save detailed logs for automation or CI workflows.                              |
| *------------ | Git Integration            | Detect Git repositories and optionally skip certain folders.                    |
| *------------ | Asset Statistics           | Show most common asset types across projects.                                   |
| *------------ | Duplicate Script Detection | Identify identical scripts across projects.                                     |
| *------------ | Cross-Platform Support     | Improve compatibility with macOS and Linux PowerShell environments.             |

---

## License

MIT License

---

## Contributing

Contributions, suggestions, and improvements are welcome.