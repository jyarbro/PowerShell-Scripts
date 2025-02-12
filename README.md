## Install Instructions
1. Run this command from powershell:
`explorer.exe (Split-Path $PROFILE)`

2. Clone this repository in the folder from the resulting window.
   
4. Restart Powershell and run the functions by name

## Script Descriptions

### Regularly useful
- [Get-YouTube.ps1](#get-youtubeps1)
- [Update-WingetPackages.ps1](#update-wingetpackagesps1)

### Occasionally useful
- [Enable-Dhcp.ps1](#enable-dhcpps1)
- [Set-StaticIPAndGateway.ps1](#set-staticipandgatewayps1)

### Rarely useful
- [Find-LongPaths.ps1](#find-longpathsps1)
- [Get-EmptyDirectory.ps1](#get-emptydirectoryps1)

### Helper functions
- [Get-DownloadsPath.ps1](#get-downloadspathps1)
- [Update-YTDLP.ps1](#update-ytdlpps1)

---

## Enable-Dhcp.ps1

**Description:**  
Defines a PowerShell function `Enable-Dhcp` that enables DHCP on an active network adapter for the specified IP address type (defaulting to IPv4). It first identifies an active adapter, then removes any existing default gateway before enabling DHCP and resetting DNS settings.

**Key Features:**

- **Active Adapter Detection:**  
  Retrieves a network adapter that is currently "up" to use for configuration.
  
- **DHCP Configuration:**  
  Checks if DHCP is disabled and, if so, removes an existing default gateway and enables DHCP.
  
- **DNS Reset:**  
  Resets DNS server addresses to defaults by automatically configuring them.

**Usage Example:**
```powershell
Enable-Dhcp -IPType "IPv4"
```

---

## Find-LongPaths.ps1

**Description:**  
Defines the `Find-LongPaths` function that recursively searches for file paths exceeding a specified character length (defaulting to 255). It uses the command-line `dir` command for a recursive, bare-format listing and then filters the results based on path length.

**Key Features:**

- **Customizable Length Parameter:**  
  Accepts an integer parameter `$length` to set the maximum allowable path length.
  
- **Pipeline Input Support:**  
  The `$length` parameter can accept pipeline input via property name.
  
- **Recursive File Enumeration:**  
  Leverages `cmd /c dir /s /b` to list all files and directories for filtering.

**Usage Example:**
```powershell
# Find file paths longer than 300 characters
Find-LongPaths -length 300
```

---

## Get-DownloadsPath.ps1

**Description:**  
Defines a function that retrieves the current user's Downloads folder path by using the Windows Known Folders API. It embeds a C# snippet to call `SHGetKnownFolderPath` from `shell32.dll`, ensuring accuracy even if the Downloads folder is relocated.

**Key Features:**

- **Embedded C# Interop:**  
  Dynamically adds a C# type (`KnownFolders`) to invoke the Windows API.
  
- **Robust Retrieval:**  
  Uses the GUID specific to the Downloads folder (`374DE290-123F-4565-9164-39C4925E467B`) to fetch the correct path.
  
- **Error Handling:**  
  Captures and reports errors if the Downloads folder path cannot be retrieved.

**Usage Example:**
```powershell
PS C:\> Get-DownloadsPath
C:\Users\YourUsername\Downloads
```

---

## Get-EmptyDirectory.ps1

**Description:**  
Defines a function `Get-EmptyDirectory` that searches for empty directories within a given path. It uses the `Get-ChildItem` cmdlet to list directories and checks each one for child items, outputting a custom object indicating whether a directory is empty.

**Key Features:**

- **Mandatory Path Parameter:**  
  Requires a `$Path` to begin the search.
  
- **Optional Recursion and Depth Control:**  
  Supports a `-Recurse` switch for recursive searching and a `-Depth` parameter (between 1 and 15) to limit the search depth.
  
- **Custom Output Object:**  
  Outputs objects with properties `EmptyDirectory` (a boolean) and `Path` for easy downstream filtering.

**Usage Example:**
```powershell
# Search recursively up to 2 levels deep for empty directories
Get-EmptyDirectory -Path "\\Server\Share\Folder" -Recurse -Depth 2
```

---

## Get-YouTube.ps1

**Description:**  
Defines a function `Get-YouTube` that downloads YouTube videos or playlists using `yt-dlp`. It supports configurable settings for the `yt-dlp` executable path and download output directory, with fallback defaults and integration with an update function (`Update-YTDLP`).

**Key Features:**

- **Flexible Parameter Defaults:**
  - **`YT_DLP_PATH`:** Uses a provided value, falls back to a global variable, or defaults to `"$env:LOCALAPPDATA\bin\yt-dlp\"`.
  - **`YT_OUTPUT_DIR`:** Uses a provided value, falls back to a global variable, or uses the output from `Get-DownloadsPath`.
  
- **Playlist Support:**  
  The `-Playlist` switch adds the `--yes-playlist` flag when downloading playlists.
  
- **Automatic Updates:**  
  Calls `Update-YTDLP` to check for updates to `yt-dlp` before downloading.
  
- **Error and Help Handling:**  
  Provides detailed help when `-Help` (or `-?`) is specified, and validates that a URL is provided.

**Usage Examples:**
```powershell
# Download a single video using default settings.
Get-YouTube -Url "https://www.youtube.com/watch?v=XXXXXX"

# Download an entire playlist.
Get-YouTube -Url "https://www.youtube.com/playlist?list=XXXXXX" -Playlist

# Use custom paths for yt-dlp and download output.
Get-YouTube -Url "https://www.youtube.com/watch?v=XXXXXX" `
           -YT_DLP_PATH "C:\Custom\yt-dlp" `
           -YT_OUTPUT_DIR "E:\MyDownloads"
```

---

## Set-StaticIPAndGateway.ps1

**Description:**  
Defines a function `Set-StaticIPAndGateway` that configures a static IPv4 address, default gateway, and DNS settings on the active network adapter. The function removes any existing IPv4 configurations before applying the new settings.

**Key Features:**

- **Configurable Parameters:**  
  - **`-IP`:** Static IP to set (defaults to `"192.168.0.100"`).
  - **`-Gateway`:** Default gateway to set (defaults to `"192.168.0.1"`).
  - **`-DNS`:** Optional DNS addresses; if omitted, defaults to the gateway address.
  
- **Active Adapter Detection:**  
  Retrieves the active network adapter (status "up") to apply settings.
  
- **Existing Configuration Removal:**  
  Removes any pre-existing IPv4 addresses and default gateway routes before setting the new configuration.
  
- **Help Option:**  
  Provides detailed help information when the `-Help` switch (or alias `?`) is used.

**Usage Examples:**
```powershell
# Configure with default DNS (using the gateway).
Set-StaticIPAndGateway -IP "192.168.0.100" -Gateway "192.168.0.1"

# Configure with custom DNS server addresses.
Set-StaticIPAndGateway -IP "192.168.0.100" -Gateway "192.168.0.1" -DNS "8.8.8.8","8.8.4.4"
```

---

## Update-WingetPackages.ps1

**Description:**  
Defines a function `Update-WingetPackages` that upgrades installed winget packages using `gsudo` for elevated privileges. The function updates the winget package sources, checks for available upgrades, upgrades each package, and, if an upgrade fails, attempts to close, uninstall, and reinstall the application.

**Key Features:**

- **gsudo Integration:**  
  Checks for and installs `gsudo` if missing, and enables caching to minimize UAC prompts.
  
- **Winget Source Update:**  
  Updates winget package sources to fetch the latest package information.
  
- **Upgrade Process:**
  - Retrieves and parses upgradeable packages via winget.
  - Upgrades each package individually.
  
- **Failure Handling:**  
  If a package fails to upgrade:
  - Attempts to gracefully close the associated application.
  - Forcefully terminates the process if necessary.
  - Uninstalls and reinstalls the package.
  
- **Restart Notification:**  
  Outputs a list of applications that may require manual restarting after the update process.

**Usage Example:**
```powershell
Update-WingetPackages
```

---

## Update-YTDLP.ps1

**Description:**  
Defines a function `Update-YTDLP` that updates the `yt-dlp` executable by checking the latest release on GitHub. It compares the release date with a locally stored timestamp, and if an update is needed, downloads and extracts the new release (specifically the `yt-dlp_win.zip` asset) into the designated folder.

**Key Features:**

- **Dynamic Installation Path:**  
  Determines the installation folder for `yt-dlp` using the provided parameter, a global variable, or a default path (`"$env:LOCALAPPDATA\bin\yt-dlp\"`).
  
- **Local Update Timestamp:**  
  Uses a `last_update.txt` file to track the last update date, preventing unnecessary updates.
  
- **GitHub API Query:**  
  Fetches release data from GitHub with appropriate headers and error handling.
  
- **Asset Extraction:**  
  Locates the asset named `yt-dlp_win.zip`, downloads it, extracts its contents, and cleans up the temporary file.
  
- **Timestamp Update:**  
  Writes the release's published date (in ISO 8601 format) to `last_update.txt` after a successful update.

**Usage Examples:**
```powershell
# Update yt-dlp using the default installation path.
Update-YTDLP

# Update yt-dlp in a custom directory.
Update-YTDLP -YT_DLP_PATH "C:\Custom\yt-dlp"
```
