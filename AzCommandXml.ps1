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
    [String] $LogFile

    AzCommand([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) {
        $ObjectType = $This.GetType()

        If($ObjectType -eq [AzCommand]) {
            Throw("Class $ObjectType must be inherited")
        }

        $This.Type = $Type
        $This.Return = $Return
        $This.Params = $Params
        $This.LogFile = $LogFile
    }

    [String] BuildCommand() {
        $CommandStr = $This.Type

        Foreach($Param in $This.Params) {
            $CommandStr = $CommandStr + " ```r`n   --" + $Param.Name + " " + $Param.Value 
        }

        Return $CommandStr
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        For($i=0; $i -lt $This.Params.Length; $i++){
            $Value =  $This.Params[$i].Value
            $Success = $False
            Do {                
                $Result = [Regex]::Match($Value,  "\{{(.*?)\}}")
                $Success = $Result.Success

                If($Success -eq $False) {
                    $This.Params[$i].Value = $Value
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

Class AzParam {
    [String] $Name
    [String] $Value

    AzParam([String] $Name, [String] $Value) {
        $This.Name = $Name
        $This.Value = $Value
    }
}


Class AzFactory {
    [AzCommand] CreateCommand([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) {
        #Write-Output "$($Type)"
        $Command = $Null
        $Arguments = @($Type, $Return, $Params, $LogFile)

        Switch ($Type){		
			"az global variables" {
				$Command = (New-Object -TypeName "AzCommandGlobalVariables" -ArgumentList $Arguments)
				Break
			}
            "az account set" {
				$Command = (New-Object -TypeName "AzAccountSet" -ArgumentList $Arguments)
				Break
			}
            "az group create" {
				$Command = (New-Object -TypeName "AzGroupCreate" -ArgumentList $Arguments)
				Break
			}
            "az keyvault create" {
				$Command = (New-Object -TypeName "AzKeyvaultCreate" -ArgumentList $Arguments)
				Break
			}
            "az network vnet create" {
				$Command = (New-Object -TypeName "AzNetworkVnetCreate" -ArgumentList $Arguments)
				Break
			}
            "az network vnet subnet create" {
				$Command = (New-Object -TypeName "AzNetworkVenetSubnetCreate" -ArgumentList $Arguments)
				Break
			}
            "az network vnet show" {
				$Command = (New-Object -TypeName "AzNetworkVnetShow" -ArgumentList $Arguments)
				Break
			}
            "az ad sp create-for-rbac" {
				$Command = (New-Object -TypeName "AzAdSpCreateForRbac" -ArgumentList $Arguments)
				Break
			}
            "az keyvault secret set" {
				$Command = (New-Object -TypeName "AzKevaultSecretSet" -ArgumentList $Arguments)
				Break
			}
            "az acr create" {
				$Command = (New-Object -TypeName "AzAcrCreate" -ArgumentList $Arguments)
				Break
			}
            "az network vnet subnet show" {
                #$Params
				$Command = (New-Object -TypeName "AzNetworkVnetSubnetShow" -ArgumentList $Arguments)
				Break
			}
            "az aks create" {
				$Command = (New-Object -TypeName "AzAksCreate" -ArgumentList $Arguments)
				Break
			}
            "az servicebus namespace create" {
				$Command = (New-Object -TypeName "AzServicebusNamespaceCreate" -ArgumentList $Arguments)
				Break
			}
            "az servicebus namespace authorization-rule keys list" {
				$Command = (New-Object -TypeName "AzServicebusNamespaceAuthorizationRuleKeysList" -ArgumentList $Arguments)
				Break
			}
            "az cosmosdb create" {
				$Command = (New-Object -TypeName "AzCosmosdbCreate" -ArgumentList $Arguments)
				Break
			}
            Default: {
                Throw("Command not supported")
            }

        }
        Return $Command
    }
}


Class AzCommandGlobalVariables : AzCommand {

    AzCommandGlobalVariables([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Return, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        For($i=0; $i -lt $This.Params.Length; $i++){
            $Value = $This.Params[$i].Value
            $Success = $False
            Do {                
                $Result = [Regex]::Match($Value,  "\{{(.*?)\}}")
                $Success = $Result.Success

                If($Success -eq $False) {
                    $Variables.Add($This.Params[$i].Name, $Value)
                    $This.Params[$i].Value = $Value
                }
                Else {
                    $FoundName = $Result.Groups[1].Value
                    $FoundValue = $Variables[$FoundName]

                    $ReplaceName = $Result.Groups[0].Value

                    $Value = $Value -Replace $ReplaceName, $FoundValue
                }
                
            } While ($Success -eq $True)
        }

        $CommandStr = $This.BuildCommand()        

        Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"

        Return $Variables
    }
}

Class AzAccountSet : AzCommand {

    AzAccountSet([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Return, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        $Variables = $This.Execute($Variables)

        $CommandStr = $This.BuildCommand()        

        Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"
        
        Invoke-Expression $CommandStr

        Return $Variables
    }
}

Class AzGroupCreate : AzCommand {

    AzGroupCreate([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Return, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Return $Variables
    }
}

Class AzKeyvaultCreate : AzCommand {

    AzKeyvaultCreate([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Return, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Return $Variables
    }
}

Class AzNetworkVnetCreate : AzCommand {

    AzNetworkVnetCreate([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Return, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Return $Variables
    }
}

Class AzNetworkVenetSubnetCreate : AzCommand {

    AzNetworkVenetSubnetCreate([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Return, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Return $Variables
    }
}

Class AzNetworkVnetShow : AzCommand {

    AzNetworkVnetShow([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Return, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Return $Variables
    }
}

Class AzAdSpCreateForRbac : AzCommand {

    AzAdSpCreateForRbac([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Return, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Return $Variables
    }
}

Class AzKevaultSecretSet : AzCommand {

    AzKevaultSecretSet([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Return, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Return $Variables
    }
}

Class AzAcrCreate : AzCommand {

    AzAcrCreate([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Return, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Return $Variables
    }
}

Class AzNetworkVnetSubnetShow : AzCommand {

    AzNetworkVnetSubnetShow([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Return, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Return $Variables
    }
}

Class AzAksCreate : AzCommand {

    AzAksCreate([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Return, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Return $Variables
    }
}

Class AzServicebusNamespaceCreate : AzCommand {

    AzServicebusNamespaceCreate([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Return, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Return $Variables
    }
}

Class AzServicebusNamespaceAuthorizationRuleKeysList : AzCommand {

    AzServicebusNamespaceAuthorizationRuleKeysList([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Return, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Return $Variables
    }
}

Class AzCosmosdbCreate : AzCommand {

    AzCosmosdbCreate([String] $Type, [String] $Return, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Return, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
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

        $Command = $Factory.CreateCommand($Type, $Return, $Params, $LogFile)
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
