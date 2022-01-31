#Using Module ".\AzCommand.psm1"
#Using Module ".\AzParam.psm1"
#Using Module ".\AzFactory.psm1"

param
(
    #required params
	[String]$OutputFolder = "C:\Temp", #$(throw "Output folder (-OutputFolder) Required"),
	[String]$Script = ".\data\deploy-aks-and-apim.ps.xml", # $(throw "XML Script (-Script) Required"),
	[String]$StopOnError = $True
)

Class AzCommand {
    [String] $Type
    [String] $Return
    [AzParam[]] $Params

    AzCommand([String] $Type, [String] $Return, [AzParam[]] $Params) {
        $ObjectType = $This.GetType()

        If($ObjectType -eq [AzCommand]) {
            Throw("Class $ObjectType must be inherited")
        }

        $This.Type = $Type
        $This.Return = $Return
        $This.Params = $Params
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Throw("Must Override Method")
    }
}

Class AzParam {
    [String] $Name
    [String] $Value

    AzParam([String] $Name, [String] $Value) {
        $This.Name = $Name
        $This.Value = $Value
    }
}


Class AzFactory {
    [AzCommand] CreateCommand([String] $Type, [String] $Return, [AzParam[]] $Params) {
        #Write-Output "$($Type)"
        $Command = $Null
        $Args = @($Type, $Return, $Params)

        Switch ($Type){		
			"az global variables" {
                #$Params
				$Command = (New-Object -TypeName "AzCommandGlobalVariables" -ArgumentList $Args)
				Break
			}
        }
        Return $Command
    }
}


Class AzCommandGlobalVariables : AzCommand {

    AzCommandGlobalVariables([String] $Type, [String] $Return, [AzParam[]] $Params) : base ($Type, $Return, $Params) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Foreach ($Param in $This.Params){
            $Value = $Param.Value
            $Success = $False
            Do {
                Write-Output "$($Value)"
                
                $Result = [Regex]::Match($Value,  "\{{(.*?)\}}")
                $Success = $Result.Success

                If($Success -eq $False) {
                    $Variables.Add($Param.Name, $Value)
                }
                Else {
                    $FoundName = $Result.Groups[1].Value
                    $FoundValue = $Variables[$FoundName]

                    $ReplaceName = $Result.Groups[0].Value

                    $Value = $Value -Replace $ReplaceName, $FoundValue
                }
                
            } While ($Success -eq $True)
        }

        Return $Variables
    }
}

Function Get-CommandParam($Params){
	$Result = @()
	Foreach ($Param in $Params){
		$Name = $Param.name.ToLower()
        $Value = $Param.value
        $Result += [AzParam]::new($Name, $Value)
	}
	
	Return $Result
}

Function Write-Log(){
	param(
        [String]$Message = $(throw "Message Required"),
        [String]$LogFile = $Null,
        [String]$Color   = $Null,
        [Switch]$AddDate = $True
    )

	$Msg = $Message
	If($AddDate) {		
		$Tempo = Get-Date -format "yyyy-MM-dd hh:mm:ss"
		$Msg = "$Tempo`t$Message"
	}


    If($Color){
		If($Msg.IndexOf("<<error>>") -ge 0) {
			$Msg = ($Msg -replace "<<error>>", "Error : ")
			Write-Host $Msg -foregroundcolor "red"
		}
		ElseIf($Msg.IndexOf("<<warning>>") -ge 0) {
			$Msg = ($Msg -replace "<<warning>>", "Warning : ")
			Write-Host $Msg -foregroundcolor "yellow"
		}
		Else {
			Write-Host $Msg -foregroundcolor $Color
		}			
    }
	Else {
       Write-Host $Msg
	}

	If($LogFile){
		$Msg | Out-File $LogFile -Append
    }
}

$Tempo = Get-Date -format "yyyyMMdd-hhmm"
$ScriptBasename = [System.IO.Path]::GetFileName($Script)
$LogFile = "$OutputFolder\Log-$ScriptBasename-$Tempo.txt"
$ErrorOccured = $False

$Data = Get-Content $Script
#$Data = ($Data -replace "&", "&amp;")
$XmlDoc = [xml]($Data)

[AzFactory] $Factory = [AzFactory]::new()

$Variables = @{}
$Commands = @()

Foreach ($AzCommand in $XmlDoc.azCommands.azCommand){
    Try {
        $Type = $AzCommand.type.ToLower();
        $Return = $AzCommand.return;
        $Params = Get-CommandParam $AzCommand.azParam

        #$Params
        #Write-Output ""

        $Command = $Factory.CreateCommand($Type, $Return, $Params)
        $Commands += $Command

        $Variables = $Command.Execute($Variables)
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
    
        Write-Log -Message "Error - $ErrorMessage - $FailedItem " -LogFile $LogFile -Color "red"
        Write-Log -Message " " -LogFile $LogFile -AddDate:$False
    
        $ErrorOccured = $True
    
        If($StopOnError -eq $True) {
            Break
        }
    }
}

Foreach ($Variable in $Variables){
    Write-Output "$($Variable)"
}

If($ErrorOccured) {
	Write-Log -Message "THE SCRIPT $ScriptBasename FAILED" -LogFile $LogFile -Color "red"
}
else {
	Write-Log -Message "THE SCRIPT $ScriptBasename COMPLETED SUCCESSFULLY" -LogFile $LogFile -Color "yellow"
}
