$ErrorActionPreference = 'SilentlyContinue'

$hives = @()
Get-ChildItem 'Registry::HKEY_USERS' -ErrorAction SilentlyContinue | Where-Object {
    $_.PSChildName -match '^S-1-5-21-[0-9-]+$'
} | ForEach-Object { $hives += ('Registry::HKEY_USERS\' + $_.PSChildName) }

$rosu = ('ROSU' + $PID)
$ntu = Join-Path $env:SystemDrive 'Users\Default\NTUSER.DAT'
$rosuLoaded = $false
if (Test-Path $ntu) {
    reg load ("HKU\" + $rosu) $ntu 2>$null | Out-Null
    if ($? -and (Test-Path ("Registry::HKEY_USERS\" + $rosu))) { $rosuLoaded = $true; $hives += ('Registry::HKEY_USERS\' + $rosu) }
}
if ($hives.Count -eq 0) { $hives += 'Registry::HKEY_USERS\.DEFAULT' }
$playOpts = @()
try { if (Test-Path -LiteralPath 'C:\ReimaginedOS-ServiceBackup\options.txt') { $playOpts = @(Get-Content -LiteralPath 'C:\ReimaginedOS-ServiceBackup\options.txt' -ErrorAction SilentlyContinue) } } catch {}
$blockTel = $playOpts -contains 'block-telemetry'
$rmAi = $playOpts -contains 'remove-ai'

function Set-HiveReg([string]$sub, [string]$name, [object]$val, [string]$type = 'DWord') {
    foreach ($h in $hives) {
        $p = Join-Path $h $sub
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name $name -Value $val -Type $type -Force
    }
}

Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Privacy' 'AdvertisingId' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Privacy' 'UserBrowsingDataEnabled' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Privacy' 'SendDiagnosticsLevelUI' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone' 'Value' 'Allow' 'String'
if ($blockTel) { Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam' 'Value' 'Deny' 'String' } else { Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam' 'Value' 'Allow' 'String' }
Set-HiveReg 'Control Panel\Accessibility' 'Sound on Activation' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Context\CloudExperienceHostIntent\Wireless' 'ScoobeCheckCompleted' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows Security Health\State' 'AccountProtection_MicrosoftAccount_Disconnected' 0 'DWord'
if ($blockTel) { Set-HiveReg 'Software\Policies\Microsoft\Windows\EdgeUI' 'DisableMFUTracking' 1 'DWord' }
if ($rmAi) { Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' 'AutoOpenCopilotLargeScreens' 0 'DWord' }
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\notifications' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\diagnostics' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\documentsLibrary' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\picturesLibrary' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\videosLibrary' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCall' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userDataTasks' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\syncWithDevices' 'Value' 'Deny' 'String'

Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Privacy' 'EnableActivityFeed' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Privacy' 'PublishUserActivities' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Privacy' 'UploadUserActivities' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Privacy' 'ShareSpeechDataWithMicrosoft' 0

Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Search' 'AllowSearchToUseLocation' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Search' 'SearchSuggestionsEnabled' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Search' 'AllowCloudSearch' 0
Set-HiveReg 'Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1

Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowSyncProviderNotifications' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0
$taskbarLeft = $false
try { if (Test-Path -LiteralPath 'C:\ReimaginedOS-ServiceBackup\options.txt') { $taskbarLeft = (Get-Content 'C:\ReimaginedOS-ServiceBackup\options.txt' -ErrorAction SilentlyContinue) -match '^taskbar-left\s*$' } } catch {}
if ($taskbarLeft) { Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAl' 0 'DWord' } else { Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAl' 1 'DWord' }
if ($playOpts -contains 'small-taskbar') { Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarSi' 0 'DWord' }
if ($playOpts -contains 'disable-transparency') { Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0 'DWord' }
if ($playOpts -contains 'no-search') { Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode' 0 'DWord' }
Set-HiveReg 'Software\AMD\CN' 'AnimationEffect' 0 'DWord'
Set-HiveReg 'Software\AMD\CN' 'AutoUpdateTriggered' 0 'DWord'
Set-HiveReg 'Software\AMD\CN' 'PowerSaverAutoEnable_cur' 0 'DWord'
if ($playOpts -contains 'legacy-context-menu') { foreach ($h in $hives) { $p = Join-Path $h 'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Set-ItemProperty -Path $p -Name '(Default)' -Value '' -Type String -Force -ErrorAction SilentlyContinue } }
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarMn' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowTaskViewButton' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCortanaButton' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_IrisRecommendations' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideRecentJumplists' 1
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarSn' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'UseOLEDTaskbarTransparency' 1
Set-HiveReg 'Control Panel\Mouse' 'RawMouseThrottleEnabled' 1
Set-HiveReg 'Control Panel\Mouse' 'RawMouseThrottleForced' 1
Set-HiveReg 'Control Panel\Mouse' 'RawMouseThrottleDuration' 20
Set-HiveReg 'Control Panel\Mouse' 'RawMouseThrottleLeeway' 0
Set-HiveReg 'Control Panel\Mouse' 'MouseTrails' 0 'String'
Set-HiveReg 'Control Panel\Mouse' 'Beep' 'No' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 1

Set-HiveReg 'Software\Microsoft\GameBar' 'AppCaptureEnabled' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\GameDVR' 'HistoricalCaptureEnabled' 0
Set-HiveReg 'Software\Microsoft\GameBar' 'ShowStartupPanel' 0


function Remove-HiveReg([string]$sub, [string]$name) {
    foreach ($h in $hives) {
        $p = Join-Path $h $sub
        if ($name -eq '') {
            Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $p -Name $name -Force -ErrorAction SilentlyContinue
        }
    }
}

Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAi' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowNewsAndInterests' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackProbes' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_ShowRecommended' 0 'DWord'
Set-HiveReg 'Software\Microsoft\DirectX\UserGpuPreferences' 'DirectXUserGlobalSettings' 'VRROptimizeEnable=0;SwapEffectUpgradeEnable=1;' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer' 'LaunchTo' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' '01' 1
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' '1024' 1
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' '2048' 30
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' '04' 1
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' '32' 0
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' '02' 0
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' '128' 0
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' '08' 0
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' '256' 0
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Personalization' 'Enabled' 0
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\BrowserSettings' 'Enabled' 0
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Credentials' 'Enabled' 0
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Accessibility' 'Enabled' 0
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Windows' 'Enabled' 0
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language' 'Enabled' 0
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync' 'SyncPolicy' 5
Set-HiveReg 'SOFTWARE\Microsoft\TabletTip\1.7' 'EnableAutocorrection' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\TabletTip\1.7' 'EnableDoubleTapSpace' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\TabletTip\1.7' 'EnablePredictionSpaceInsertion' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\TabletTip\1.7' 'EnableSpellchecking' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\TabletTip\1.7' 'EnableTextPrediction' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'ShowFrequent' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'ShowRecent' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'ClearRecentDocsOnExit' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoRecentDocsHistory' 1 'DWord'
Set-HiveReg 'SOFTWARE\Policies\Microsoft\Windows\Explorer' 'NoRemoteDestinations' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\EventHandlersDefaultSelection\CameraAlternate' '(Default)' 'MSTakeNoAction' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\EventHandlersDefaultSelection\StorageOnArrival' '(Default)' 'MSTakeNoAction' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\UserChosenExecuteHandlers\CameraAlternate\ShowPicturesOnArrival' '(Default)' 'MSTakeNoAction' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\UserChosenExecuteHandlers\StorageOnArrival' '(Default)' 'MSTakeNoAction' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CDP\SettingsPage' 'BluetoothLastDisabledNearShare' '0' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CDP' 'NearShareChannelUserAuthzPolicy' '0' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CDP' 'CdpSessionUserAuthzPolicy' '1' 'String'

Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Search' 'BackgroundAppGlobalToggle' 0 'DWord'
Set-HiveReg 'Control Panel\Cursors' 'GestureVisualization' '0' 'String'
Set-HiveReg 'Control Panel\Cursors' 'ContactVisualization' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Shell\USB' 'NotifyOnUsbErrors' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Shell\USB' 'NotifyOnWeakCharger' '0' 'String'
Set-HiveReg 'Control Panel\Accessibility' 'Warning Sounds' '0' 'String'
Set-HiveReg 'Keyboard Layout\Toggle' 'Layout Hotkey' '3' 'String'
Set-HiveReg 'Keyboard Layout\Toggle' 'Language Hotkey' '3' 'String'
Set-HiveReg 'Keyboard Layout\Toggle' 'Hotkey' '3' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Themes' 'ThemeChangesMousePointers' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Themes' 'ThemeChangesDesktopIcons' '0' 'String'
Set-HiveReg 'Software\Policies\Microsoft\office\16.0\common' 'sendcustomerdata' 0 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\office\common\clienttelemetry' 'sendtelemetry' 3 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\office\16.0\common' 'qmenable' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\MediaPlayer\Preferences' 'AcceptedPrivacyStatement' '1' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\MediaPlayer\Preferences' 'UsageTracking' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContentEnabled' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'RemediationRequired' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'RotatingLockScreenEnabled' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'RotatingLockScreenOverlayEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideRecentlyAddedApps' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications' 'EnableAccountNotifications' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoResolveSearch' '1' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoResolveTrack' '1' 'String'
Remove-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'NoPreviousVersionsPage'
Set-HiveReg 'Control Panel\Desktop' 'FontSmoothing' '2' 'String'
Set-HiveReg 'Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) 'Binary'
Set-HiveReg 'SOFTWARE\Microsoft\Multimedia\Audio\DeviceCpl' 'ShowDisconnectedDevices' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Multimedia\Audio\DeviceCpl' 'ShowHiddenDevices' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'IconsOnly' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 3 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\TabletTip\1.7' 'EnableAutoShiftEngage' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\TabletTip\1.7' 'EnableKeyAudioFeedback' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoInstrumentation' '1' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement' 'ScoobeSystemSettingEnabled' '0' 'String'
Set-HiveReg 'Software\Microsoft\Lighting' 'AmbientLightingEnabled' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume' 'Value' '1' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Ease of Access' 'selfscan' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Ease of Access' 'selfvoice' '0' 'String'
Set-HiveReg 'Control Panel\Accessibility\SlateLaunch' 'LaunchAT' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'AutoCheckSelect' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'MultipleInvokePromptMinimum' '100' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates' 'ShortcutNameTemplate' '"%s.lnk"' 'String'
$hb90 = [byte[]]@(0x00, 0x00, 0x00, 0x00)
foreach ($h in $hives) { $p = Join-Path $h 'Software\Microsoft\Windows\CurrentVersion\Explorer'; if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }; Set-ItemProperty -Path $p -Name 'link' -Value $hb90 -Type Binary -Force }
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'UseCompactMode' '1' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'MultiTaskingAltTabFilter' '3' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoLowDiskSpaceChecks' '1' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_Layout' '1' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'DontUsePowerShellOnWinX' '1' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell' 'SignInMode' '1' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\PenWorkspace' 'PenWorkspaceAppSuggestionsEnabled' '0' 'String'
Remove-HiveReg 'SOFTWARE\Policies\Microsoft\PreviousVersions' 'DisableLocalPage'
Remove-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MultiTaskingView\AllUpView' 'Enabled'
Set-HiveReg 'Software\Microsoft\Windows\Shell\Copilot\BingChat' 'IsUserEligible' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowSyncProviderNotifications' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'DisableFlipAhead' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowRecent' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowFrequent' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_IrisRecommendations' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_AccountNotifications' 0 'DWord'
Set-HiveReg 'Control Panel\International\User Profile' 'HttpAcceptLanguageOptOut' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'StartTrackDocs' 0 'DWord'
Set-HiveReg 'SOFTWARE\Policies\Microsoft\Windows\Explorer' 'HideRecommendedSection' 1 'DWord'
Set-HiveReg 'Control Panel\Desktop' 'WaitToKillAppTimeout' '2000' 'String'
Set-HiveReg 'Control Panel\Mouse' 'SnapToDefaultButton' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarMn' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'DisablePreviewDesktop' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskViewButton' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowTaskViewButton' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Hidden' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowSuperHidden' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' '{645FF040-5081-101B-9F08-00AA002F954E}' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' '{2cc5cae3-caa0-4448-b7e2-9286b73e2026}' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 0 'DWord'
if ($playOpts -contains 'dark-mode') { Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'SystemUsesLightTheme' 0 'DWord'; Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'AppsUseLightTheme' 0 'DWord' }
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'ShowRecommendations' 0 'DWord'
Set-HiveReg 'Control Panel\Accessibility\StickyKeys' 'Flags' '506' 'String'
Set-HiveReg 'Control Panel\Accessibility\MouseKeys' 'Flags' '130' 'String'
Set-HiveReg 'Control Panel\Accessibility\HighContrast' 'Flags' '4194' 'String'
Set-HiveReg 'Control Panel\Cursors' 'PenVisualization' 0 'DWord'
Set-HiveReg 'Control Panel\Desktop' 'AutoColorization' 0 'DWord'
Set-HiveReg 'Control Panel\Desktop' 'SmoothScroll' 0 'DWord'
Set-HiveReg 'Control Panel\Personalization\Desktop Slideshow' 'AnimationDuration' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'DisablePreviewDesktop' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'DisablePreviewWindow' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'NoNetCrawling' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackCachedFileUpdaterContract' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackConnectedSearchHistory' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackEnabled' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackOpenPickerContract' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackSavePickerContract' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackSearchContract' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackShareContractMFU' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarFlashOverrideBreatheCount' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\BamThrottling' 'DisableWindowHinting' 1 'DWord'
Set-HiveReg 'SOFTWARE\Policies\Microsoft\Windows\Explorer' 'DisableThumbsDBOnNetworkFolders' 1 'DWord'
Set-HiveReg 'SOFTWARE\Policies\Microsoft\Windows\Explorer' 'SkipNetworkShieldCheck' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' 'TaskbarEndTask' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager' 'EnthusiastMode' 1 'DWord'
Set-HiveReg 'Control Panel\Desktop' 'JPEGImportQuality' 100 'DWord'
Set-HiveReg 'Control Panel\Sound' 'Beep' 'no' 'String'
Set-HiveReg 'Control Panel\Desktop' 'ActiveWndTrkTimeout' 10 'DWord'
Set-HiveReg 'Control Panel\Desktop' 'DragFullWindows' '1' 'String'
Set-HiveReg 'Control Panel\Desktop\WindowMetrics' 'MinAnimate' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ListviewAlphaSelect' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ListviewShadow' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackProgs' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'AltTabSettings' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'HoverSelectDesktops' 0 'DWord'
Set-HiveReg 'SOFTWARE\Policies\Microsoft\Windows\Explorer' 'DisableNotificationCenter' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer' 'ShowCloudFilesInQuickAccess' 0 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackDocs' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackRunMRU' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'SeparateProcess' 1 'DWord'
Set-HiveReg 'Control Panel\Accessibility\ToggleKeys' 'Flags' '58' 'String'
Set-HiveReg 'Control Panel\Accessibility\Keyboard Response' 'Flags' '122' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers' 'DisableAutoplay' 1 'DWord'
Set-HiveReg 'Control Panel\Keyboard' 'KeyboardDelay' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\ShowJumpView' 'Microsoft.Copilot_8wekyb3d8bbwe!App' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun' '1' 'DeviceCensus.exe' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCortanaButton' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language' 'Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-202914Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-88000326Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'DisallowRun' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\input\Settings' 'InsightsEnabled' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings' 'NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments' 'SaveZoneInformation' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0 'DWord'
Set-HiveReg 'SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\CloudContent' 'ConfigureWindowsSpotlight' 2 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\CloudContent' 'DisableTailoredExperiencesWithDiagnosticData' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsSpotlightFeatures' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\CloudContent' 'DisableThirdPartySuggestions' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsSpotlightWindowsWelcomeExperience' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsSpotlightOnActionCenter' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsSpotlightOnSettings' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\Windows Error Reporting' 'Disabled' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\WindowsAI' 'AllowRecallEnablement' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 0 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsSpotlightOnLockScreen' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appointments' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCallHistory' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\documentsLibrary' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\email' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\broadFileSystemAccess' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\chat' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCall' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\picturesLibrary' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\radios' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userDataTasks' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\videosLibrary' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\Policies\Microsoft\Windows\CloudContent' 'IncludeEnterpriseSpotlight' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Speech_OneCore\Preferences' 'VoiceActivationOn' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Speech_OneCore\Preferences' 'VoiceActivationEnableAboveLockscreen' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Speech_OneCore\Preferences' 'ModelDownloadAllowed' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps' 'AgentActivationEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps' 'AgentActivationLastUsed' '' 'String'
Set-HiveReg 'Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps' 'AgentActivationOnLockScreenEnabled' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Clipboard' 'CloudClipboardAutomaticUpload' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Clipboard' 'CloudClipRDPOverride' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Input\Settings' 'UserStatsEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\Security\EnergySaver' 'EnergyRecommendations' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Notepad' 'ShowStoreBanner' 0 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\EdgeUI' 'TurnOffBackstack' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\EdgeUI' 'DisableRecentApps' 1 'DWord'
Set-HiveReg 'Control Panel\Mouse' 'DoubleClickSpeed' '480' 'String'
Set-HiveReg 'Control Panel\Mouse' 'MouseHoverTime' '100' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoLowDiskSpaceChecks' 1 'DWord'
Set-HiveReg 'Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' 'System.IsPinnedToNameSpaceTree' 0 'DWord'
Set-HiveReg 'Software\Classes\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' 'System.IsPinnedToNameSpaceTree' 0 'DWord'
Set-HiveReg 'Control Panel\Mouse' 'ActiveWindowTracking' 0 'DWord'
Set-HiveReg 'Control Panel\Mouse' 'MouseAccel' '0' 'String'
Set-HiveReg 'Control Panel\Desktop' 'ScreenSaveActive' '0' 'String'
Set-HiveReg 'Control Panel\Desktop' 'ScreenSaveTimeOut' '0' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CloudStore' 'DisableRoamingSync' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Search' 'DeviceHistoryEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Search' 'HistoryViewEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Search' 'VoiceShortcut' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Search' 'CanCortanaBeEnabled' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Search' 'CortanaEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' 'NOC_GLOBAL_SETTING_BADGE_ENABLED' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' 'NOC_GLOBAL_SETTING_SHOW_IN_SETTINGS' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CDP' 'RomeSdkChannelUserAuthzPolicy' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CDP' 'DragTrayEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'JointResize' 0 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Assistance\Client\1.0' 'NoOnlineAssist' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Assistance\Client\1.0' 'NoExplicitFeedback' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Assistance\Client\1.0' 'NoImplicitFeedback' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\WindowsMovieMaker' 'WebHelp' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\WindowsMovieMaker' 'CodecDownload' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\WindowsMovieMaker' 'WebPublish' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ImmersiveShell' 'ConvertibleSlateModePromptPreference' 2 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAppsVisibleInTabletMode' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAutoHideInTabletMode' 0 'DWord'
Remove-HiveReg 'Control Panel\Accessibility\MouseKeys' 'MaximumSpeed'
Remove-HiveReg 'Control Panel\Accessibility\MouseKeys' 'TimeToMaximumSpeed'
Remove-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3' 'Settings'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoRemoteChangeNotify' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoRemoteRecursiveEvents' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'TurnOffSPIAnimations' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoRecentDocsMenu' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoSMHelp' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\DriverSearching' 'DriverUpdateWizardWuSearchEnabled' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Input\TIPC' 'Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Feeds' 'ShellFeedsTaskbarViewMode' 2 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\Explorer' 'HidePeopleBar' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform' 'NoGenTicket' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack' 'ShowedToastAtLevel' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Siuf\Rules' 'NumberOfSIUFInPeriod' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Siuf\Rules' 'NoSIUFInPeriod' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Siuf\Rules' 'NoPromptAgain' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Siuf\Rules' 'PeriodInNanoSeconds' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\GameBar' 'AllowAutoGameMode' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\GameBar' 'ShowStartupPanel' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\GameBar' 'GamePanelStartupTipIndex' 3 'DWord'
Set-HiveReg 'SYSTEM\GameConfigStore' 'GameDVR_Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\GameBar\LiveCapture' 'ShowWatermark' 0 'DWord'
Set-HiveReg 'Software\Microsoft\GameBar\LiveCapture' 'ShowTimer' 0 'DWord'
Set-HiveReg 'Software\Microsoft\GameBar\LiveCapture' 'ShowBanner' 0 'DWord'
Set-HiveReg 'Software\Microsoft\GameBar\Broadcast' 'AllowBroadcast' 0 'DWord'
Set-HiveReg 'Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1 'DWord'
Set-HiveReg 'Software\Microsoft\GameBar' 'EnableCaptureSampling' 0 'DWord'
Set-HiveReg 'Software\Microsoft\GameBar' 'GamePanelStartupKeyAlignment' 0 'DWord'
Set-HiveReg 'System\GameConfigStore' 'GameDVR_DSEBehavior' 2 'DWord'
Set-HiveReg 'System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2 'DWord'
Set-HiveReg 'System\GameConfigStore' 'GameDVR_HonorUserFSEBehaviorMode' 1 'DWord'
Set-HiveReg 'System\GameConfigStore' 'GameDVR_FSEBehavior' 2 'DWord'
Set-HiveReg 'System\GameConfigStore' 'GameDVR_DXGIHonorFSEWindowsCompatible' 1 'DWord'
Set-HiveReg 'System\GameConfigStore' 'GameDVR_EFSEFeatureFlags' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad' 'WpadOverride' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Narrator\NoRoam' 'WinEnterLaunchEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\DirectX\UserGpuPreferences' 'C:\Windows\explorer.exe' 'GpuPreference=2;' 'String'
Set-HiveReg 'Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize' 'StartupDelayInMSec' 0 'DWord'
Set-HiveReg 'Control Panel\Desktop' 'HungAppTimeout' '2000' 'String'
Set-HiveReg 'Control Panel\Desktop' 'AutoEndTasks' '1' 'String'
Set-HiveReg 'Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' 'FolderType' 'NotSpecified' 'String'
Set-HiveReg 'Control Panel\Keyboard' 'PrintScreenKeyForSnippingEnabled' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'DisallowShaking' 1 'DWord'
Set-HiveReg 'Control Panel\Mouse' 'MouseSpeed' '0' 'String'
Set-HiveReg 'Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
Set-HiveReg 'Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Multimedia\Audio' 'UserDuckingPreference' 3 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsDeviceSearchHistoryEnabled' 0 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\CloudContent' 'DisableTailoredExperiencesWithDiagnosticData' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 1 'DWord'
Set-HiveReg 'SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisablePCA' 1 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SystemPaneSuggestionsEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEverEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'OemPreInstalledAppsEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SoftLandingEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'ContentDeliveryAllowed' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'RotatingLockScreenEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'RotatingLockScreenOverlayEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338387Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338388Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338389Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338393Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-353694Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-353696Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-353698Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-310093Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-314559Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-314563Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-280815Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-370697Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-370700Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-400923Enabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\AppManagement\AppSettings' 'ArchiveAppsEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsAADCloudSearchEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsMSACloudSearchEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsMSFTCloudSearchEnabled' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'SafeSearchMode' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration' 'IsResumeAllowed' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\LooselyCoupled' 'Value' 'Deny' 'String'
Set-HiveReg 'Software\NVIDIA Corporation\NVControlPanel2\Client' 'OptInOrOutPreference' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'HideSCAMeetNow' 1 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'HidePeopleBar' 1 'DWord'
Set-HiveReg 'SOFTWARE\Policies\Microsoft\Windows\Explorer' 'DisableNotificationCenter' 1 'DWord'
Set-HiveReg 'Software\Policies\Microsoft\Windows\CurrentVersion\QuietHours' 'Enable' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings' 'NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\DWM' 'EnableAeroPeek' 0 'DWord'
Set-HiveReg 'SOFTWARE\Microsoft\Windows\DWM' 'AlwaysHibernateThumbnails' 0 'DWord'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'IsBatteryPercentageEnabled' 1
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowSecondsInSystemClock' 1
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Feeds' 'ShellFeedsEnabled' 0
Set-HiveReg 'Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}' 'System.IsPinnedToNameSpaceTree' 0
Set-HiveReg 'Software\Policies\Microsoft\Windows\CloudContent' 'DisableSpotlightCollectionOnDesktop' 1
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' 'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' 'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' 'NOC_GLOBAL_SETTING_TOASTS_ENABLED' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\PushNotifications' 'ToastEnabled' 0
Set-HiveReg 'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications' 'NoTileApplicationNotification' 1
Set-HiveReg 'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications' 'NoToastApplicationNotification' 1
Set-HiveReg 'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications' 'NoToastApplicationNotificationOnLockScreen' 1

$extraCaps = @('gazeInput','humanPresence','humanInterfaceDevice','spatialPerception','backgroundSpatialPerception','bluetooth','bluetoothSync','wifiData','wifiDirect','cellularData','generativeAI','eyeTracker','voiceActivation','activity','voipCall','phoneCallHistoryPublic','sms','sensors.custom','userNotificationListener')
foreach ($h in $hives) {
  foreach ($c in $extraCaps) {
    foreach ($base in @("Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\$c", "Software\Classes\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\$c") ) {
      $b = Join-Path $h $base
      if (-not (Test-Path $b)) { New-Item -Path $b -Force | Out-Null }
      Set-ItemProperty -Path $b -Name 'Value' -Value 'Deny' -Type String -Force -ErrorAction SilentlyContinue
      $np = Join-Path $b 'NonPackaged'
      if (-not (Test-Path $np)) { New-Item -Path $np -Force | Out-Null }
      Set-ItemProperty -Path $np -Name 'Value' -Value 'Deny' -Type String -Force -ErrorAction SilentlyContinue
    }
  }
}
foreach ($c in $extraCaps) {
  $mb = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\$c"
  if (-not (Test-Path $mb)) { New-Item -Path $mb -Force | Out-Null }
  Set-ItemProperty -Path $mb -Name 'Value' -Value 'Deny' -Type String -Force -ErrorAction SilentlyContinue
}

$sx = [byte[]]@(0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xC0,0xCC,0x0C,0x00,0x00,0x00,0x00,0x00,0x80,0x99,0x19,0x00,0x00,0x00,0x00,0x00,0x40,0x66,0x26,0x00,0x00,0x00,0x00,0x00,0x00,0x33,0x33,0x00,0x00,0x00,0x00,0x00)
$sy = [byte[]]@(0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x38,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x70,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xA8,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xE0,0x00,0x00,0x00,0x00,0x00)
foreach ($h in $hives) {
  $mp = Join-Path $h 'Control Panel\Mouse'
  if (-not (Test-Path $mp)) { New-Item -Path $mp -Force | Out-Null }
  Set-ItemProperty -Path $mp -Name 'SmoothMouseXCurve' -Value $sx -Type Binary -Force -ErrorAction SilentlyContinue
  Set-ItemProperty -Path $mp -Name 'SmoothMouseYCurve' -Value $sy -Type Binary -Force -ErrorAction SilentlyContinue
}

$termGuid = '{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}'
foreach ($h in $hives) {
  $tp = Join-Path $h 'Console\%%Startup'
  if (-not (Test-Path $tp)) { New-Item -Path $tp -Force | Out-Null }
  Set-ItemProperty -Path $tp -Name 'DelegationConsole' -Value $termGuid -Type String -Force -ErrorAction SilentlyContinue
  Set-ItemProperty -Path $tp -Name 'DelegationTerminal' -Value $termGuid -Type String -Force -ErrorAction SilentlyContinue
}

Set-HiveReg 'Software\Policies\Microsoft\Windows\Explorer' 'NoBalloonFeatureAdvertisements' 1
Set-HiveReg 'Software\Policies\Microsoft\Windows\Explorer' 'NoAutoTrayNotify' 1
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowInfoTip' 0
Set-HiveReg 'Control Panel\Desktop' 'LowLevelHooksTimeout' '1000' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState' 'FullPath' 1
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'LinkResolveIgnoreLinkInfo' 1
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoDriveTypeAutoRun' 255
Set-HiveReg 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'DisableGraphRecentItems' 1
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'DisallowShaking' 1
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowSyncProviderNotifications' 0

$edgeGone = -not (Test-Path "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") -and -not (Test-Path "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe")
if ($edgeGone) {
    foreach ($h in $hives) {
        Remove-ItemProperty -Path (Join-Path $h 'Software\Microsoft\Windows\CurrentVersion\Run') -Name 'Microsoft Edge Update' -Force -ErrorAction SilentlyContinue
        foreach ($ext in @('.html','.htm','.shtml','.svg','.webp','.xhtml','.xht','.xml')) {
            Remove-ItemProperty -Path (Join-Path $h ("Software\Classes\$ext\OpenWithProgIds")) -Name 'MSEDGEHTM' -Force -ErrorAction SilentlyContinue
        }
    }
}
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'NoNetCrawling' 1
Set-HiveReg 'Control Panel\Desktop' 'AutoEndTasks' '1' 'String'
Set-HiveReg 'Control Panel\Desktop' 'MenuShowDelay' '1' 'String'
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\PushNotifications' 'NoCloudApplicationNotification' 1
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\GameDVR' 'CursorCaptureEnabled' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AudioCaptureEnabled' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\GameDVR' 'MicrophoneCaptureEnabled' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\GameDVR' 'ShowStartupPanel' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\GameDVR' 'UseNexusForGameBarEnabled' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsDynamicSearchBoxEnabled' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsMSACloudSearchEnabled' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsAADCloudSearchEnabled' 0
Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsDeviceSearchHistoryEnabled' 0
foreach ($h in ($hives | Where-Object { $_ -like '*ROSU*' })) {
    try {
        $bp = Join-Path $h 'Software\Microsoft\Windows\Shell\Bags\1\Desktop'
        New-Item -Path $bp -Force | Out-Null
        Set-ItemProperty -Path $bp -Name FFlags -Value 1075839525 -Type DWord -Force
        Set-ItemProperty -Path $bp -Name Mode -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $bp -Name LogicalViewMode -Value 3 -Type DWord -Force
        Set-ItemProperty -Path $bp -Name IconSize -Value 48 -Type DWord -Force
        Set-ItemProperty -Path $bp -Name Sort -Value ([byte[]](0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0x30,0xF1,0x25,0xB7,0xEF,0x47,0x1A,0x10,0xA5,0xF1,0x02,0x60,0x8C,0x9E,0xEB,0xAC,0x0E,0,0,0,1,0,0,0)) -Type Binary -Force
        Set-ItemProperty -Path $bp -Name GroupView -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $bp -Name GroupByDirection -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $bp -Name 'GroupByKey:FMTID' -Value '{00000000-0000-0000-0000-000000000000}' -Type String -Force
        Set-ItemProperty -Path $bp -Name 'GroupByKey:PID' -Value 0 -Type DWord -Force
        Remove-ItemProperty -Path $bp -Name GroupBy -Force -ErrorAction SilentlyContinue
        $sh = Join-Path $bp 'Shell\{5C4F28B5-F869-4E84-8E60-F11DB97C5CC7}'
        New-Item -Path $sh -Force | Out-Null
        Set-ItemProperty -Path $sh -Name FFlags -Value 1075839525 -Type DWord -Force
        Set-ItemProperty -Path $sh -Name Mode -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $sh -Name LogicalViewMode -Value 3 -Type DWord -Force
        Set-ItemProperty -Path $sh -Name IconSize -Value 48 -Type DWord -Force
        Set-ItemProperty -Path $sh -Name Sort -Value ([byte[]](0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0x30,0xF1,0x25,0xB7,0xEF,0x47,0x1A,0x10,0xA5,0xF1,0x02,0x60,0x8C,0x9E,0xEB,0xAC,0x0E,0,0,0,1,0,0,0)) -Type Binary -Force
        Remove-ItemProperty -Path $sh -Name GroupBy -Force -ErrorAction SilentlyContinue
    } catch {}
}
try {
    foreach ($h in $hives) {
        try {
            Get-Item -Path (Join-Path $h 'Software\Microsoft\Windows\CurrentVersion\Run') -ErrorAction Stop | Select-Object -ExpandProperty Property | Where-Object { $_ -like 'MicrosoftEdgeAutoLaunch_*' } | ForEach-Object {
                Remove-ItemProperty -Path (Join-Path $h 'Software\Microsoft\Windows\CurrentVersion\Run') -Name $_ -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }
} catch {}
if (($playOpts -contains 'install-open-shell') -or ($playOpts -contains 'svc-extreme')) {
    Set-HiveReg 'Software\OpenShell\StartMenu' 'ShowedStyle2' 1
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'RecentPrograms' 'None' 'String'
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'RecentMetroApps' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'EnableJumplists' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'HybridShutdown' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'StartScreenShortcut' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'AutoStart' 1
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'HighlightNew' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'HighlightNewApps' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'ShiftClick' 'ClassicMenu' 'String'
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'ShiftWin' 'ClassicMenu' 'String'
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'CheckWinUpdates' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'SearchTrack' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'SearchAutoComplete' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'SearchPath' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'SearchMetroApps' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'SearchMetroSettings' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'SearchKeywords' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'SearchSubWord' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'SearchFiles' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'SearchContents' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'SearchCategories' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'SearchInternet' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'MoreResults' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'MainMenuAnimate' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'NumericSort' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'FontSmoothing' 'None' 'String'
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'MenuShadow' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'EnableGlass' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'GlassOverride' 1
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'GlassColor' 2039583
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'SkinW7' 'Immersive' 'String'
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'SkinVariationW7' '' 'String'
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'SkinOptionsW7' @('LIGHT=0','DARK=1','AUTO=0','USER_IMAGE=0','USER_NAME=0','CENTER_NAME=0','SMALL_ICONS=1','OPAQUE=1','DISABLE_MASK=0','BLACK_TEXT=0','BLACK_FRAMES=0','TRANSPARENT_LESS=0','TRANSPARENT_MORE=0') 'MultiString'
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'SkipMetro' 1
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'NoSearchBox' 1
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'PreCacheIcons' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'EnableAccelerators' 0
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'CustomTaskbar' 1
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'TaskbarLook' 'Opaque' 'String'
    Set-HiveReg 'Software\OpenShell\StartMenu\Settings' 'TaskbarColor' 1315860
    Set-HiveReg 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAl' 1
}
try {
    $optFile = 'C:\ReimaginedOS-ServiceBackup\options.txt'
    $opts = @()
    if (Test-Path -LiteralPath $optFile) { $opts = @(Get-Content -LiteralPath $optFile -ErrorAction SilentlyContinue) }
    $runMap = @(
        @('remove-onedrive', @('OneDrive', 'OneDriveSetup')),
        @('remove-teams', @('com.squirrel.Teams.Teams', 'Microsoft Teams', 'MSTeams')),
        @('remove-edge', @('MicrosoftEdgeAutoLaunch_0', 'MicrosoftEdgeAutoLaunch_1', 'Microsoft Edge Update', 'Edge')),
        @('remove-apps', @('Cortana')),
        @('remove-bloat', @('Cortana'))
    )
    foreach ($pair in $runMap) {
        if ($opts -contains $pair[0]) {
            foreach ($h in $hives) {
                foreach ($n in $pair[1]) {
                    Remove-ItemProperty -Path (Join-Path $h 'Software\Microsoft\Windows\CurrentVersion\Run') -Name $n -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
                } catch {}
if ($rosuLoaded -and (Test-Path ("Registry::HKEY_USERS\" + $rosu))) {
    [gc]::Collect(); Start-Sleep -Milliseconds 300
    reg unload ("HKU\" + $rosu) 2>$null | Out-Null
}
exit 0