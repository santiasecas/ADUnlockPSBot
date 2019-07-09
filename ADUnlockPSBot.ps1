Import-Module -Name "PoshGram"
$Chatids = XXXX, YYYY #Must be an array of chat_id of the allowed users (for only one user, put 0 as one chat_id)
$Tokenbot = "123456:AABBCCDDEEFFGGHHIIJJ"
$Init = 1

#Creates an array with all domain users
$NetUser = (net user /domain)
$LineCount = ($NetUser | Measure).Count
$Count = $LineCount-3
do {
    $LineList = $NetUser[$Count].split(' ')
    $UserList += $LineList -ne ""
    $Count -= 1
}
while ($Count -gt 3)

#Reads messages from Telegram bot and unlocks user accounts
do {
	$Date = Get-Date -format 'dd/MM/yyyy hh:mm:ss'
	$LastId = $UltId
	$Request = 'https://api.telegram.org/bot123456:AABBCCDDEEFFGGHHIIJJ/getUpdates'
	Try {
		$Messages = Invoke-webrequest $Request | convertfrom-json | select -expand result | select -expand message | select message_id
		
		if($Messages -ne $null){
			$MessCount = $Messages.length
			[int]$cid = (Invoke-webrequest $Request | convertfrom-json | select -expand result | select -expand message | select -expand from | select id)[$MessCount - 1].id
			$Text = (Invoke-webrequest $Request | convertfrom-json | select -expand result | select -expand message | select Text)[$MessCount - 1].Text
			$UltId = $Messages[$Messages.length - 1].message_id
			#This is to avoid executing the last message when bot is restarted
			if($Init -eq 1){
				Add-Content c:\log_ps.txt "$Date - Bot started"
				$LastId = $UltId
				$Init = 0
			}
		}
		if($LastId -ne $UltId){
			if($Chatids.contains($cid)){
				if($Text -ne $null -and $UserList.contains($Text)){
					net user /domain $Text /active:yes
					send-telegramtextmessage -bottoken $Tokenbot -chatid $cid -message "User $Text unlocked"
					Add-Content c:\log_ps.txt "$Date - User $Text unlocked"
				} else{
					if($Text -ne 'ping'){
						send-telegramtextmessage -bottoken $Tokenbot -chatid $cid -message "User $Text does not exists"
						Add-Content c:\log_ps.txt "$Date - Trying to unlock user $Text"
					} else{
						send-telegramtextmessage -bottoken $Tokenbot -chatid $cid -message "pong"
					}
				}
			} else{
				Add-Content c:\log_ps.txt "$Date - User $cid sends text $Text"
			}
			$LastId = $UltId
		}
	} Catch {
		Add-Content c:\log_ps.txt "$Date - One error ocurred."
	}
	Start-sleep -seconds 10
}until($Init -lt 0)