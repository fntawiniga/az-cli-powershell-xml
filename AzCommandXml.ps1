#Using Module ".\AzCommand.psm1"
#Using Module ".\AzParam.psm1"
#Using Module ".\AzFactory.psm1"

param
(
    #required params
	[String] $OutputFolder = "C:\Temp", #$(throw "Output folder (-OutputFolder) Required"),
	[String] $Script = ".\data\deploy-aks-and-apim2.ps.xml", # $(throw "XML Script (-Script) Required"),
	[String] $StopOnError = $False
)

Class AzParam {
    [String] $Name
    [String] $Value

    AzParam([String] $Name, [String] $Value) {
        $This.Name = $Name
        $This.Value = $Value
    }
}

Class AzBase {
    [String] $Name
    [AzParam[]] $Params
    [String] $LogFile

    AzBase([String] $Name, [AzParam[]] $Params, [String] $LogFile) {
        $ObjectType = $This.GetType()

        If($ObjectType -eq [AzBase]) {
            Throw("Class $ObjectType must be inherited")
        }

        $This.Name = $Name
        $This.Params = $Params
        $This.LogFile = $LogFile
    }

    [String] BuildCommand([Boolean] $AddQuoteToParam) {
        $CommandStr = "`r`n" + $This.Name

        Foreach($Param in $This.Params) {
            If($AddQuoteToParam) {
                $CommandStr = $CommandStr + " ```r`n   --" + $Param.Name + " `"" + $Param.Value + "`""
            }
            Else {
                $CommandStr = $CommandStr + " ```r`n   --" + $Param.Name + " " + $Param.Value + ""
            }            
        }

        Return $CommandStr
    }

    [Void] ReplaceParamsTokens([Hashtable] $Variables) {
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
    }

    [String] FindParamValueByName([String] $Name) {
        $Value = ""
        $Found  = $False

        Foreach($Param in $This.Params) {
            If($Param.Name -eq $Name) {
                $Value = $Param.Value
                $Found = $True
                Break
            }
        }

        If($Found -eq $False) {
            Throw("Parameter By $($Name) Name Does Not Exist")
        }

        Return $Value
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        
        Throw("Method must be inherited")
        Return $Variables
    }
}

Class AzCheckExist : AzBase {
    [String] $compareWith

    AzCheckExist([String] $CompareWith, [String] $Name, [AzParam[]] $Params, [String] $LogFile) : base($Name, $Params, $LogFile) {
        $This.CompareWith = $CompareWith
    }


    [Hashtable] Execute([Hashtable] $Variables) {
        
       
        Return $Variables
    }
}

Class AzCommand : AzBase {
    [String] $Type
    [AzCheckExist] $CheckExist

    AzCommand([String] $Type, [String] $Name, [String] $Output, [AzCheckExist] $CheckExist, [AzParam[]] $Params, [String] $LogFile) : base($Name, $Params, $LogFile) {
        $ObjectType = $This.GetType()

        If($ObjectType -eq [AzCommand]) {
            Throw("Class $ObjectType must be inherited")
        }

        $This.Type = $Type
        $This.CheckExist = $CheckExist
    }
}

Class AzFactory {
    [AzCommand] CreateCommand([String] $Type, [String] $Name, [String] $Output, [AzCheckExist] $CheckExist, [AzParam[]] $Params, [String] $LogFile) {
        $Command = $Null
        $Arguments = @($Type, $Name, $Output, $CheckExist, $Params, $LogFile)

        Switch ($Type){	
            "execute" {
                Switch ($Name){		
                    "az global variables" {
                        $Command = (New-Object -TypeName "AzCommandGlobalVariables" -ArgumentList $Arguments)
                        Break
                    }
                    Default: {
                        $Command = (New-Object -TypeName "AzCommandExecute" -ArgumentList $Arguments)
                    }
                }
                Break
            }
            "execute-query" {
                $Command = (New-Object -TypeName "AzCommandExecuteQuery" -ArgumentList $Arguments)
                Break
            }
            "query" {
                $Command = (New-Object -TypeName "AzCommandQuery" -ArgumentList $Arguments)
                Break
            }
            Default: {
                Throw("Type $($Type) not implemented")
            }
        }

        Return $Command
    }
}


Class AzCommandGlobalVariables : AzCommand {

    AzCommandGlobalVariables([String] $Type, [String] $Name, [String] $Output, [AzCheckExist] $CheckExist, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $CheckExist, $Params, $LogFile) {
      
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

        $CommandStr = $This.BuildCommand($False)        

        Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"

        Return $Variables
    }
}

Class AzCommandExecute : AzCommand {

    AzCommandExecute([String] $Type, [String] $Name, [String] $Output, [AzCheckExist] $CheckExist, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $CheckExist, $Params, $LogFile) {
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        $This.ReplaceParamsTokens($Variables)

        $ResourceGroup = $This.FindParamValueByName("name")

        $CheckStr = "`r`n`$Check = `$(az group exists"
        $CheckStr = $CheckStr + " ```r`n   --name `"" + $ResourceGroup + "`")"

        Write-Log -Message $CheckStr -LogFile $This.LogFile -Color "green"

        $Check = $False
        Invoke-Expression $CheckStr

        If ($Check -eq $True) {
            Write-Log -Message "The command $($This.Name) has been already executed. The corresponding resource already exists" -LogFile $This.LogFile -Color "yellow"
        }
        Else {        
            Write-Log -Message "Executing the command $($This.Name) ..." -LogFile $This.LogFile -Color "green"
            $CommandStr = $This.BuildCommand($False)        

            Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"

            Try {
                $SshKeyValue = $This.FindParamValueByName("ssh-key-value")

                $AksSshFilename = $SshKeyValue.Substring(0, $SshKeyValue.LastIndexOf('.'))
                Write-Output "y" | ssh-keygen -b 2048 -t rsa -f $AksSshFilename -q -N """"

                Write-Log -Message "SSH Key $($AksSshFilename) has been successfully created" -LogFile $This.LogFile -Color "green"
            }
            Catch {

            }

            $CommandStr = $CommandStr + "`r`n `$ErrorFound = `$?"

            $ErrorFound = $False
            Invoke-Expression $CommandStr

            If (!$ErrorFound) {
                Throw("Error executing the command $($This.Name)")
            }
            Else {
                Write-Log -Message "The command $($This.Name) has been successfully executed" -LogFile $This.LogFile -Color "green"
            }
        }  
    
        Return $Variables
    }
}


Class AzCommandAksCreate : AzCommand {

    AzCommandAksCreate([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $Params, $LogFile) {
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Try {
            $This.ReplaceParamsTokens($Variables)
            
            $AksName = $This.FindParamValueByName("name")
            $ResourceGroup = $This.FindParamValueByName("resource-group")

            $CheckStr = "`r`n`$Name = `$(az aks show"
            $CheckStr = $CheckStr + " ```r`n   --name `"" + $AksName + "`""
            $CheckStr = $CheckStr + " ```r`n   --resource-group `"" + $ResourceGroup + "`""
            $CheckStr = $CheckStr + " ```r`n   --query name"
            $CheckStr = $CheckStr + " ```r`n   --output tsv)"

            Write-Log -Message $CheckStr -LogFile $This.LogFile -Color "green"

            $Name = $Null
            Invoke-Expression $CheckStr

            If ($Name -eq $AksName) {
                Write-Log -Message "Azure Kubernates Service $AksName already exists" -LogFile $This.LogFile -Color "yellow"
            }
            Else {        
                Write-Log -Message "Creating Azure Kubernates Service $AksName ..." -LogFile $This.LogFile -Color "green"

                $CommandStr = $This.BuildCommand($False)        

                Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"

                Try {
                    $SshKeyValue = $This.FindParamValueByName("ssh-key-value")

                    $AksSshFilename = $SshKeyValue.Substring(0, $SshKeyValue.LastIndexOf('.'))
                    Write-Output "y" | ssh-keygen -b 2048 -t rsa -f $AksSshFilename -q -N """"

                    Write-Log -Message "SSH Key $($AksSshFilename) has been successfully created" -LogFile $This.LogFile -Color "green"
                }
                Catch {

                }
            
                $CommandStr = $CommandStr + "`r`n `$ErrorFound = `$?"

                $ErrorFound = $False
                Invoke-Expression $CommandStr

                If (!$ErrorFound) {
                    Throw("Error creating Azure Kubernates Service $($AksName)")
                }
                Else {
                    Write-Log -Message "Azure Kubernates Service $($AksName) has been successfully created" -LogFile $This.LogFile -Color "green"
                }                
            }  
        }
        Catch {
            Throw($_.Exception.Message)
        }

        Return $Variables
    }
}




Class AzCommandQuery : AzCommand {

    AzCommandQuery([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        $This.ReplaceParamsTokens($Variables)

        $Value = $This.Output

        $Success = $False            
        $Result = [Regex]::Match($Value,  "\{{(.*?)\}}")
        $Success = $Result.Success

        If($Success -eq $True) {
            $Output = $Null
            $CommandStr = "`r`n`$Output = `$(" + $This.BuildCommand($False) + ")"      

            Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"
            
            $CommandStr = $CommandStr + "`r`n `$ErrorFound = `$?"

            $ErrorFound = $False
            Invoke-Expression $CommandStr

            If (!$ErrorFound) {
                Throw("Error running a query")
            }
            Else {
                Write-Log -Message "Query has been successfully ran" -LogFile $This.LogFile -Color "green"
            }   
            
            $FoundName = $Result.Groups[1].Value
            $Variables.Add( $FoundName, $Output)
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
		$Msg = "`r`n$Tempo`t$Message"
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
        $Type = $AzCommand.type;
        $Name = $AzCommand.name.ToLower();
        $Output = $AzCommand.output;
        $Params = Get-CommandParam $AzCommand.azParam

        $Command = $Factory.CreateCommand($Type, $Name, $Output, $Params, $LogFile)
        $Commands += $Command

        $Variables = $Command.Execute($Variables)
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        #$FailedItem = $_.Exception.ItemName
    
        Write-Log -Message "$ErrorMessage" -LogFile $LogFile -Color "red"
        Write-Log -Message " " -LogFile $LogFile -AddDate:$False
    
        $ErrorOccured = $True
    
        If($StopOnError -eq $True) {
            Break
        }
    }
}

If($ErrorOccured) {
	Write-Log -Message "THE SCRIPT $ScriptBasename FAILED" -LogFile $LogFile -Color "red"
}
else {
	Write-Log -Message "THE SCRIPT $ScriptBasename COMPLETED SUCCESSFULLY" -LogFile $LogFile -Color "yellow"
}
