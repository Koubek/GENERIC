param (
    [parameter(Mandatory=$true)]
    [string] $WinClientDirectory,
    [parameter(Mandatory=$true)]
    [string] $ClickOnceApplicationFilesDirectory
)

Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Framework.UI.dll"                            -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Framework.UI.Extensibility.dll"              -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Framework.UI.Extensibility.xml"              -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Framework.UI.Navigation.dll"                 -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Framework.UI.UX2006.dll"                     -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Framework.UI.UX2006.WinForms.dll"            -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Framework.UI.Windows.dll"                    -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Framework.UI.WinForms.Controls.dll"          -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Framework.UI.WinForms.DataVisualization.dll" -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Framework.UI.WinForms.dll"                   -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Nav.Client.Builder.dll"                      -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Nav.Client.exe"                              -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Nav.Client.exe.config"                       -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Nav.Client.ServiceConnection.dll"            -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Nav.Client.UI.dll"                           -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Nav.Client.WinClient.dll"                    -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Nav.Client.WinForms.dll"                     -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Nav.DocumentService.dll"                     -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Nav.DocumentService.Types.dll"               -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Nav.Language.dll"                            -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Nav.OpenXml.dll"                             -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Nav.SharePointOnlineDocumentService.dll"     -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Nav.Types.dll"                               -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Nav.Types.Report.dll"                        -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Dynamics.Nav.Watson.dll"                              -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Office.Interop.Excel.dll"                             -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Office.Interop.OneNote.dll"                           -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Office.Interop.Outlook.dll"                           -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Microsoft.Office.Interop.Word.dll"                              -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Newtonsoft.Json.dll"                                            -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Office.dll"                                                     -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\RapidStart.ico"                                                 -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\System.Collections.Immutable.dll"                               -Destination "$ClickOnceApplicationFilesDirectory"
Copy-Item "$WinClientDirectory\Add-ins"                                                        -Destination "$ClickOnceApplicationFilesDirectory\Add-ins" -Recurse
Copy-Item "$WinClientDirectory\Images"                                                         -Destination "$ClickOnceApplicationFilesDirectory\Images"  -Recurse
Get-ChildItem -Path "$WinClientDirectory\??-??" -Directory | % {
    $Name = $_.Name
    Copy-Item "$WinClientDirectory\$Name" -Destination "$ClickOnceApplicationFilesDirectory\$Name" -Recurse
}
