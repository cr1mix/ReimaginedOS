param([switch]$Brave, [switch]$Chrome, [switch]$Firefox, [switch]$UBlock)
$ErrorActionPreference = 'SilentlyContinue'

function Write-BrowserPolicy([string]$Path, [hashtable]$Values, [string]$Type = 'DWord') {
    $reg = "Registry::$Path"
    if (-not (Test-Path $reg)) { New-Item $reg -Force | Out-Null }
    foreach ($kv in $Values.GetEnumerator()) {
        Set-ItemProperty -Path $reg -Name $kv.Key -Type $Type -Value $kv.Value -Force
    }
}

function Merge-Json($Base, $Patch) {
    if ($null -eq $Patch) { return }
    foreach ($p in $Patch.PSObject.Properties) {
        if ($Base.PSObject.Properties[$p.Name] -and
            ($Base.PSObject.Properties[$p.Name].Value -is [System.Management.Automation.PSCustomObject]) -and
            ($p.Value -is [System.Management.Automation.PSCustomObject])) {
            Merge-Json $Base.PSObject.Properties[$p.Name].Value $p.Value
        } else {
            $Base | Add-Member -Name $p.Name -Value $p.Value -MemberType NoteProperty -Force
        }
    }
}

function Write-Profile([string]$Path, [string]$Json) {
    $enc = [System.Text.UTF8Encoding]::new($false)
    $dir = Split-Path $Path
    if (-not (Test-Path $dir)) { New-Item $dir -ItemType Directory -Force | Out-Null }
    if (Test-Path $Path) {
        try {
            $base = Get-Content $Path -Raw -ErrorAction Stop | ConvertFrom-Json
            Merge-Json $base ($Json | ConvertFrom-Json)
            [System.IO.File]::WriteAllText($Path, ($base | ConvertTo-Json -Depth 20), $enc)
            return
        } catch {}
    }
    [System.IO.File]::WriteAllText($Path, $Json, $enc)
}

$defaultLocal = "$env:SystemDrive\Users\Default\AppData\Local"
$chromState = '{"background_mode":{"enabled":false},"browser":{"first_run_finished":true},"user_experience_metrics":{"reporting_enabled":false}}'
$braveState = '{"background_mode":{"enabled":false},"browser":{"first_run_finished":true},"user_experience_metrics":{"reporting_enabled":false},"brave":{"p3a":{"enabled":false},"stats":{"reporting_enabled":false}},"p3a":{"enabled":false},"stats":{"reporting_enabled":false}}'

if ($Chrome) {
    if (Test-Path $defaultLocal) {
        $userDir = Join-Path $defaultLocal 'Google\Chrome\User Data'
        Write-Profile "$userDir\Default\Preferences" '{"privacy_sandbox":{"m1":{"ad_measurement_enabled":false,"fledge_enabled":false,"topics_enabled":false,"row_notice_acknowledged":true}},"privacy_guide":{"viewed":true},"signin":{"allowed_on_next_startup":false},"extensions":{"ui":{"developer_mode":true}}}'
        Write-Profile "$userDir\Local State" $chromState
    }
    Write-BrowserPolicy 'HKLM\SOFTWARE\Policies\Google\Chrome' @{
        MetricsReportingEnabled = 0; PrivacySandboxPromptEnabled = 0
        UrlKeyedAnonymizedDataCollectionEnabled = 0; WebRtcEventLogCollectionAllowed = 0
        CloudReportingEnabled = 0; SafeBrowsingExtendedReportingEnabled = 0
        WebRtcMultipleRoutesEnabled = 0
    }
    if ($UBlock) {
        Write-BrowserPolicy 'HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionSettings\cjpalhdlnbpafiamejdnhcphjbkeiagm' @{
            'installation_mode' = 'normal_installed'; 'update_url' = 'https://clients2.google.com/service/update2/crx'
        } 'String'
    }
    Write-Host 'Chrome hardened'
}

if ($Brave) {
    if (Test-Path $defaultLocal) {
        $userDir = Join-Path $defaultLocal 'BraveSoftware\Brave-Browser\User Data'
        Write-Profile "$userDir\Default\Preferences" '{"brave":{"p3a":{"enabled":false,"notice_acknowledged":true},"stats":{"reporting_enabled":false},"brave_vpn":{"show_button":false},"rewards":{"inline_tip_buttons_enabled":false,"show_brave_rewards_button_in_location_bar":false},"wallet":{"show_wallet_icon_on_toolbar":false},"webtorrent_enabled":false,"enable_window_closing_confirm":false,"new_tab_page":{"hide_all_widgets":true,"show_brave_news":false,"show_stats":false,"show_together":false,"show_brave_vpn":false},"shields":{"advanced_view_enabled":true}},"enable_do_not_track":true,"user_experience_metrics":{"reporting_enabled":false},"browser":{"first_run_finished":true,"has_seen_welcome_page":true,"enable_window_closing_confirm":false},"privacy_sandbox":{"m1":{"ad_measurement_enabled":false,"fledge_enabled":false,"topics_enabled":false}},"profile":{"password_manager_enabled":false,"content_settings":{"exceptions":{"shieldsAds":{"*,*":{"setting":2}}}}},"extensions":{"ui":{"developer_mode":true}}}'
        Write-Profile "$userDir\Local State" $braveState
    }
    Write-BrowserPolicy 'HKLM\SOFTWARE\Policies\BraveSoftware\Brave' @{
        BraveVPNDisabled = 1; BraveRewardsDisabled = 1; BraveWalletDisabled = 1
        BraveAIChatEnabled = 0; MetricsReportingEnabled = 0; TorDisabled = 1
        SafeBrowsingExtendedReportingEnabled = 0; WebRtcMultipleRoutesEnabled = 0
    }
    if ($UBlock) {
        Write-BrowserPolicy 'HKLM\SOFTWARE\Policies\BraveSoftware\Brave\ExtensionSettings\cjpalhdlnbpafiamejdnhcphjbkeiagm' @{
            'installation_mode' = 'normal_installed'; 'update_url' = 'https://clients2.google.com/service/update2/crx'
        } 'String'
    }
    Write-Host 'Brave hardened'
}

if ($Firefox) {
    $ffPolicy = '{"policies":{"DisableTelemetry":true,"DisableFirefoxStudies":true,"DisablePocket":true,"DisableDefaultBrowserAgent":true,"CaptivePortal":false,"FirefoxHome":{"SponsoredTopSites":false,"SponsoredPocket":false},"Preferences":{"app.normandy.api_url":"","app.normandy.enabled":false,"browser.aboutConfig.showWarning":false,"browser.contentblocking.category":{"Value":"strict","Status":"user"},"browser.crashReports.unsubmittedCheck.autoSubmit":false,"browser.download.manager.addToRecentDocs":false,"browser.newtabpage.activity-stream.discoverystream.enabled":false,"browser.newtabpage.activity-stream.feeds.telemetry":false,"browser.newtabpage.activity-stream.showSponsored":false,"browser.newtabpage.activity-stream.showSponsoredTopSites":false,"browser.newtabpage.activity-stream.telemetry":false,"browser.pagethumbnails.capturing_disabled":true,"browser.ping-centre.telemetry":false,"browser.search.suggest.enabled":false,"browser.shell.checkDefaultBrowser":false,"browser.tabs.crashReporting.sendReport":false,"browser.tabs.warnOnClose":false,"browser.tabs.warnOnCloseOtherTabs":false,"browser.urlbar.quicksuggest.enabled":false,"browser.urlbar.speculativeConnect.enabled":false,"datareporting.healthreport.uploadEnabled":false,"datareporting.policy.dataSubmissionEnabled":false,"dom.battery.enabled":false,"dom.private-attribution.submission.enabled":false,"dom.security.https_only_mode":true,"geo.provider.network.url":"","media.peerconnection.ice.default_address_only":true,"media.peerconnection.ice.no_host":true,"network.cookie.sameSite.laxByDefault":{"Value":true,"Status":"user"},"network.cookie.sameSite.noneRequiresSecure":{"Value":true,"Status":"user"},"network.cookie.sameSite.schemeful":{"Value":true,"Status":"user"},"network.predictor.enabled":false,"network.prefetch-next":false,"privacy.trackingprotection.enabled":true,"toolkit.telemetry.archive.enabled":false,"toolkit.telemetry.bhrPing.enabled":false,"toolkit.telemetry.coverage.opt-out":true,"toolkit.telemetry.firstShutdownPing.enabled":false,"toolkit.telemetry.newProfilePing.enabled":false,"toolkit.telemetry.server":"data:,","toolkit.telemetry.shutdownPingSender.enabled":false,"toolkit.telemetry.unified":false,"toolkit.telemetry.updatePing.enabled":false},"ExtensionSettings":{"uBlock0@raymondhill.net":{"install_url":"https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi","installation_mode":"normal_installed"}}}}'
    foreach ($dir in @("$env:ProgramFiles\Mozilla Firefox", "${env:ProgramFiles(x86)}\Mozilla Firefox")) {
        if (Test-Path $dir) {
            $distDir = Join-Path $dir 'distribution'
            if (-not (Test-Path $distDir)) { New-Item $distDir -ItemType Directory -Force | Out-Null }
            Write-Profile (Join-Path $distDir 'policies.json') $ffPolicy
        }
    }
    try {
        Stop-Service -Name 'MozillaMaintenance' -Force -ErrorAction SilentlyContinue
        Set-Service -Name 'MozillaMaintenance' -StartupType Disabled -ErrorAction SilentlyContinue
        $mm = Join-Path ${env:ProgramFiles(x86)} 'Mozilla Maintenance Service\uninstall.exe'
        if (Test-Path -LiteralPath $mm) { Start-Process -FilePath $mm -ArgumentList '/S' -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue }
    } catch {}
    Write-Host 'Firefox hardened'
}
exit 0