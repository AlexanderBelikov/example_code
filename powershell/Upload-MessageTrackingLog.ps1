# Created by: Alexander Belikov

Param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if($_ -notmatch "^\d{4}\d{2}(\d{2})?$"){
            throw "DateFilter not match format YYYYMM or YYYYMMDD";
        }
        $true
    })]
    $DateFilter
)
Begin {

    # Get root diectory and script settings
    $ScriptRoot = $PSScriptRoot;
    $ScriptSettings = Import-PowershellDataFile "$ScriptRoot\Settings.psd1"
    
    # Credentials
    $Credential_MSE = New-Object System.Management.Automation.PsCredential($ScriptSettings.Credentials.MSE.UserName,$(ConvertTo-SecureString -String $ScriptSettings.Credentials.MSE.Password));

    # MessageTrackingLog path list
    $LogPathList = $ScriptSettings.LogPathList;

    # Mount MessageTrackingLog Path Drive Name
    $DriveName = "MessageTrackingLog";
}
Process {
    #----------------------------------------------------------------------------------------------------
    #   Append-MessageTrackingLog
    function Append-MessageTrackingLog {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true)]
            [String]$Path,
            [Parameter(Mandatory=$true)]
            [String]$DateFilter
        )
        $ErrorActionPreference = "Stop";

        $PathEscaped = $Path | %{ $_.Replace("\","\\") };
        $bash_args = "-c `"/mnt/e/scripts/ClickHouse/MSE-MessageTrackingLog/Append-MessageTrackingLog.sh '$PathEscaped' '$DateFilter'`"";
        $Process = Start-Process -FilePath "bash" -ArgumentList $bash_args -Wait -PassThru -NoNewWindow;
        if($Process.ExitCode -ne 0){
            Write-Error "Append-MessageTrackingLog $Path - ExitCode: $($Process.ExitCode)" -ErrorAction Stop;
        }
    }
    #   Append-MessageTrackingLog
    #----------------------------------------------------------------------------------------------------
    #   Export-MessageTrackingLogReport
    function Export-MessageTrackingLogReport {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true)]
            [String]$DateFilter
        )
        $ErrorActionPreference = "Stop";

        $bash_output = "$ScriptRoot\bash\bash_output.txt";
        $bash_error = "$ScriptRoot\bash\bash_error.txt";
        $bash_args = "-c `"/mnt/e/scripts/ClickHouse/MSE-MessageTrackingLog/Export-MessageTrackingLogReport.sh '$DateFilter'`"";
        $Process = Start-Process -FilePath "bash" -ArgumentList $bash_args -Wait -PassThru -NoNewWindow -RedirectStandardOutput $bash_output -RedirectStandardError $bash_error;
        if($Process.ExitCode -ne 0){
            Write-Error "Export-MessageTrackingLogReport '$DateFilter' - ExitCode: $($Process.ExitCode); Message: $(Get-Content $bash_error | Out-String)" -ErrorAction Stop;
            return $null;
        }
    }
    #   Export-MessageTrackingLogReport
    #----------------------------------------------------------------------------------------------------
    #   Check-MessageTrackingLog
    function Check-MessageTrackingLog {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true)]
            [String]$DateFilter
        )
        $ErrorActionPreference = "Stop";

        $bash_output = "$ScriptRoot\bash\bash_output.txt";
        $bash_error = "$ScriptRoot\bash\bash_error.txt";
        $bash_args = "-c `"/mnt/e/scripts/ClickHouse/MSE-MessageTrackingLog/Check-MessageTrackingLog.sh '$DateFilter'`"";
        $Process = Start-Process -FilePath "bash" -ArgumentList $bash_args -Wait -PassThru -NoNewWindow -RedirectStandardOutput $bash_output -RedirectStandardError $bash_error;
        if($Process.ExitCode -ne 0){
            Write-Error "Check-MessageTrackingLog '$DateFilter' - ExitCode: $($Process.ExitCode); Message: $(Get-Content $bash_error | Out-String)" -ErrorAction Stop;
        }
        $Output = Get-Content $bash_output;
        if($Output -notmatch "^(0|1)$"){
            Write-Error "Check-MessageTrackingLog '$DateFilter' Output not match '^(0|1)$'" -ErrorAction Stop;
        }

        if([convert]::ToInt32($Output) -eq 1){
            return $true;
        } else {
            return $false;
        }
    }
    #   Check-MessageTrackingLog
    #----------------------------------------------------------------------------------------------------
    #   Upload-MessageTrackingLog
    function Upload-MessageTrackingLog {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true)]
            [String]$Path,
            [Parameter(Mandatory=$true)]
            [String]$DateFilter
        )
        $ErrorActionPreference = "Stop";

        $PathEscaped = $Path | %{ $_.Replace("\","\\") };
        $bash_args = "-c `"/mnt/e/scripts/ClickHouse/MSE-MessageTrackingLog/Upload-MessageTrackingLog.sh '$PathEscaped' '$DateFilter'`"";
        $Process = Start-Process -FilePath "bash" -ArgumentList $bash_args -Wait -PassThru -NoNewWindow;
        if($Process.ExitCode -ne 0){
            Write-Error "Upload-MessageTrackingLog $Path - ExitCode: $($Process.ExitCode)" -ErrorAction Stop;
        }
    }
    #   Upload-MessageTrackingLog
    #----------------------------------------------------------------------------------------------------
    #   Main

    $ErrorActionPreference = "Stop";

    foreach($LogPath in $LogPathList){
        $i++;
        Write-Progress -Activity "$DateFilter - $LogPath" -Status "$i/$($LogPathList.Count)" -PercentComplete $($i/$($LogPathList.Count)*100);
        New-PSDrive -Name $DriveName -PSProvider filesystem -Root $LogPath -Credential $Credential_MSExchange | Out-Null;
        Upload-MessageTrackingLog -Path $LogPath -DateFilter $DateFilter;
        Remove-PSDrive -Name $DriveName;
    }

    #   Main
    #----------------------------------------------------------------------------------------------------
}

End {
}


