function Sendmail($body)
{
	$emailFrom = "Dr.Nick@quickstart.local"
	$emailTo = "helpdesk@example.com" #who gets the alerts? 
	$subject = "The Following Servers need Attention"
	$smtpServer = "smtp.example.com" #your SMTP server here
	$smtp = new-object Net.Mail.SmtpClient($smtpServer)
	$smtp.Send($emailFrom, $emailTo, $subject, $body)
}

function DriveStat($computer)
{
    $driveData = Get-WmiObject -class win32_LogicalDisk -computer $computer
    foreach($drive in $driveData)
    {
        if(($drive.Size -ne $null) -and ($drive.DriveType -eq 3))
        {
            $pctFree = ($drive.FreeSpace/$drive.Size)
			if($pctFree -le .2)
			{
				$computer | out-file "C:\PSHealth\.WarningData" -append
				$ServerDiskStats =  @{"Disk"=$drive.DeviceID;"Size"= ("{0:N1}" -f ($drive.Size/1GB))+'GB';"Free Space"= ("{0:N1}" -f ($drive.FreeSpace/1GB))+'GB';"% Free"= ("{0:N0}" -f ($pctFree*100))+'%'}
				$ServerDiskStats | out-file "C:\PSHealth\.WarningData" -append
			}
        }
    }
}

function SQLStat($computer)
{
	$colFiles = Get-Wmiobject -namespace "root\CIMV2" -computername $computer -Query "Select * from CIM_LogicalFile Where Extension = 'ldf'"
	foreach ($objFile in $colFiles)
	{
		if($objFile.FileName -ne $null)
		{
			if(($objFile.FileSize/1GB) > 2)
			{
				$computer | out-file "C:\PSHealth\.WarningData" -append
				$LogFileStats = @{'File Name' = $objFile.FileName;'File Size' = ("{0:N1}" -f ($objFile.FileSize/1GB))+'GB';}
				$LogFileStats | out-file "C:\PSHealth\.WarningData" -append
			}
		}
	}
}
$starttime = Get-Date
add-content C:\PSHealth\ServerDoctor-log.log "`n-----------------------`n"
add-content C:\PSHealth\ServerDoctor-log.log "`nServerDoctor began a domain scan at $starttime "
$servers = Get-Content "C:\PSHealth\config.txt"
New-Item "C:\PSHealth\.WarningData" -type file

foreach($machine in $servers)
{
	DriveStat($machine)
	SQLStat($machine)
    $date = Get-Date 
    add-content C:\PSHealth\ServerDoctor-log.log "`nServerDoctor Crawled $machine at $date"
}

$report = Get-Content "C:\PSHealth\.WarningData" | out-string
if($report -ne "")
{
    Sendmail($report)
    add-content C:\PSHealth\ServerDoctor-log.log "`nAfter Examining the above servers, ServerDoctor found the following errors:`n$report"
}
else
{
    add-content C:\PSHealth\ServerDoctor-log.log "`nNo Errors Found`n"
}
add-content C:\PSHealth\ServerDoctor-log.log "`n--------------------`n"
Remove-Item "C:\PSHealth\.WarningData" 
