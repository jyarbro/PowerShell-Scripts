function Get-DownloadsPath {
    <#
    .SYNOPSIS
        Retrieves the current user's Downloads folder path using the Windows Known Folders API.

    .DESCRIPTION
        This function uses a small embedded C# snippet to interop with shell32.dll in order
        to get the Downloads folder path as defined by Windows. This method works even if your
        Downloads folder is on a different drive.

    .EXAMPLE
        PS C:\> Get-DownloadsPath
        C:\Users\YourUsername\Downloads
    #>

    # If the KnownFolders type is not yet loaded, add it.
    if (-not ("KnownFolders" -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class KnownFolders {
    // GUID for the Downloads folder
    private static readonly Guid DownloadsFolderGuid = new Guid("374DE290-123F-4565-9164-39C4925E467B");
    [DllImport("shell32.dll")]
    public static extern int SHGetKnownFolderPath([MarshalAs(UnmanagedType.LPStruct)] Guid rfid, uint dwFlags, IntPtr hToken, out IntPtr ppszPath);
    public static string GetDownloadsPath() {
        IntPtr pPath;
        int result = SHGetKnownFolderPath(DownloadsFolderGuid, 0, IntPtr.Zero, out pPath);
        if(result >= 0) {
            string path = Marshal.PtrToStringUni(pPath);
            Marshal.FreeCoTaskMem(pPath);
            return path;
        }
        throw new Exception("Could not get the Downloads folder path. HRESULT: " + result.ToString());
    }
}
"@
    }

    try {
        return [KnownFolders]::GetDownloadsPath()
    }
    catch {
        Write-Error "Failed to retrieve Downloads folder path: $_"
    }
}
