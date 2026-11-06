param([Parameter(Mandatory=$true)][int]$TestProcessId)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$root=[System.Windows.Automation.AutomationElement]::RootElement
$deadline=(Get-Date).AddSeconds(15)
do {
  $condition=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty,$TestProcessId)
  $window=$root.FindFirst([System.Windows.Automation.TreeScope]::Children,$condition)
  if($null -ne $window){
    $sourceCondition=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty,'OpenMeeting Interop RGB - Google Chrome')
    $source=$window.FindFirst([System.Windows.Automation.TreeScope]::Descendants,$sourceCondition)
    if($null -ne $source){break}
  }
  Start-Sleep -Milliseconds 200
}while((Get-Date) -lt $deadline)
if($null -eq $source){throw 'Test RGB source not found in the Windows screen picker'}
$source.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
$shareCondition=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty,([string][char]0x5171+[char]0x4eab))
$share=$window.FindFirst([System.Windows.Automation.TreeScope]::Descendants,$shareCondition)
if($null -eq $share){throw 'System share button missing'}
$share.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
'{"selected":"OpenMeeting Interop RGB","pass":true}'
