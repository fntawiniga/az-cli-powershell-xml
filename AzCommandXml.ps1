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

Class AzCommand {
    [String] $Type
    [String] $Name
    [String] $Output
    [AzParam[]] $Params
    [String] $LogFile

    AzCommand([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) {
        $ObjectType = $This.GetType()

        If($ObjectType -eq [AzCommand]) {
            Throw("Class $ObjectType must be inherited")
        }

        $This.Type = $Type
        $This.Name = $Name
        $This.Output = $Output
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

Class AzParam {
    [String] $Name
    [String] $Value

    AzParam([String] $Name, [String] $Value) {
        $This.Name = $Name
        $This.Value = $Value
    }
}


Class AzFactory {
    [AzCommand] CreateCommand([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) {
        $Command = $Null
        $Arguments = @($Type, $Name, $Output, $Params, $LogFile)

        If ($Type -eq "execute" -or $Type -eq "execute-query") {
            Switch ($Name){		
                "az global variables" {
                    $Command = (New-Object -TypeName "AzCommandGlobalVariables" -ArgumentList $Arguments)
                    Break
                }
                "az account set" {
                    $Command = (New-Object -TypeName "AzCommandAccountSet" -ArgumentList $Arguments)
                    Break
                }
                "az group create" {
                    $Command = (New-Object -TypeName "AzCommandGroupCreate" -ArgumentList $Arguments)
                    Break
                }
                "az keyvault create" {
                    $Command = (New-Object -TypeName "AzCommandKeyvaultCreate" -ArgumentList $Arguments)
                    Break
                }
                "az network vnet create" {
                    $Command = (New-Object -TypeName "AzCommandNetworkVnetCreate" -ArgumentList $Arguments)
                    Break
                }
                "az network vnet subnet create" {
                    $Command = (New-Object -TypeName "AzCommandNetworkVnetSubnetCreate" -ArgumentList $Arguments)
                    Break
                }
                "az ad sp create-for-rbac" {
                    $Command = (New-Object -TypeName "AzCommandAdSpCreateForRbac" -ArgumentList $Arguments)
                    Break
                }
                "az keyvault secret set" {
                    $Command = (New-Object -TypeName "AzCommandKevaultSecretSet" -ArgumentList $Arguments)
                    Break
                }
                "az acr create" {
                    $Command = (New-Object -TypeName "AzCommandAcrCreate" -ArgumentList $Arguments)
                    Break
                }
                "az aks create" {
                    $Command = (New-Object -TypeName "AzCommandAksCreate" -ArgumentList $Arguments)
                    Break
                }
                "az servicebus namespace create" {
                    $Command = (New-Object -TypeName "AzCommandServicebusNamespaceCreate" -ArgumentList $Arguments)
                    Break
                }
                "az cosmosdb create" {
                    $Command = (New-Object -TypeName "AzCommandCosmosdbCreate" -ArgumentList $Arguments)
                    Break
                }
                "az apim create" {
                    $Command = (New-Object -TypeName "AzCommandApimCreate" -ArgumentList $Arguments)
                    Break
                }
                "az resource update" {
                    $Command = (New-Object -TypeName "AzCommandResourceUpdate" -ArgumentList $Arguments)
                    Break
                }
                Default: {
                    Throw("Command not supported")
                }
            }
        }
        Else { #query         
            $Command = (New-Object -TypeName "AzCommandQuery" -ArgumentList $Arguments)
        }
        Return $Command
    }
}


Class AzCommandGlobalVariables : AzCommand {

    AzCommandGlobalVariables([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $Params, $LogFile) {
      
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

Class AzCommandAccountSet : AzCommand {

    AzCommandAccountSet([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        $This.ReplaceParamsTokens($Variables)

        $CommandStr = $This.BuildCommand($True)      

        Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"
        
        $CommandStr = $CommandStr + "`r`n `$ErrorFound = `$?"

        $ErrorFound = $False
        Invoke-Expression $CommandStr

        If (!$ErrorFound) {
            Throw("Error setting subscription")
        }
        Else {
            Write-Log -Message "Azure Subscription has been successfully set" -LogFile $This.LogFile -Color "green"
        }    

        Return $Variables
    }
}

Class AzCommandGroupCreate : AzCommand {

    AzCommandGroupCreate([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $Params, $LogFile) {
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
            Write-Log -Message "Resource Group $($ResourceGroup) already exists" -LogFile $This.LogFile -Color "yellow"
        }
        Else {        
            Write-Log -Message "Creating Resource Group $($ResourceGroup) ..." -LogFile $This.LogFile -Color "green"
            $CommandStr = $This.BuildCommand($False)        

            Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"

            $CommandStr = $CommandStr + "`r`n `$ErrorFound = `$?"

            $ErrorFound = $False
            Invoke-Expression $CommandStr

            If (!$ErrorFound) {
                Throw("Error creating resource group $($ResourceGroup)")
            }
            Else {
                Write-Log -Message "Resource Group $($ResourceGroup) has been create" -LogFile $This.LogFile -Color "green"
            }
        }  
    
        Return $Variables
    }
}

Class AzCommandKeyvaultCreate : AzCommand {

    AzCommandKeyvaultCreate([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        $This.ReplaceParamsTokens($Variables)
        
        $KeyVault = $This.FindParamValueByName("name")
        $ResourceGroup = $This.FindParamValueByName("resource-group")

        $CheckStr = "`r`n`$Name = `$(az keyvault show"
        $CheckStr = $CheckStr + " ```r`n   --name `"" + $KeyVault + "`""
        $CheckStr = $CheckStr + " ```r`n   --resource-group `"" + $ResourceGroup + "`""
        $CheckStr = $CheckStr + " ```r`n   --query name"
        $CheckStr = $CheckStr + " ```r`n   --output tsv)"

        Write-Log -Message $CheckStr -LogFile $This.LogFile -Color "green"

        $Name = $Null
        Invoke-Expression $CheckStr

        If ($Name -eq $KeyVault) {
            Write-Log -Message "Azure KeyVault $KeyVault already exists" -LogFile $This.LogFile -Color "yellow"
        }
        Else {        
            Write-Log -Message "Creating Azure KeyVault $KeyVault ..." -LogFile $This.LogFile -Color "green"

            $CommandStr = $This.BuildCommand($False)        

            Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"

            $CommandStr = $CommandStr + "`r`n `$ErrorFound = `$?"

            $ErrorFound = $False
            Invoke-Expression $CommandStr
    
            If (!$ErrorFound) {
                Throw("Error creating Azure KeyVault $($KeyVault)")
            }
            Else {
                Write-Log -Message "Azure KeyVault $($KeyVault) has been successfully created" -LogFile $This.LogFile -Color "green"
            }            
        }  

        Return $Variables
    }
}

Class AzCommandNetworkVnetCreate : AzCommand {

    AzCommandNetworkVnetCreate([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        $This.ReplaceParamsTokens($Variables)
        
        $VnetName = $This.FindParamValueByName("name")
        $ResourceGroup = $This.FindParamValueByName("resource-group")

        $CheckStr = "`r`n`$Name = `$(az network vnet show"
        $CheckStr = $CheckStr + " ```r`n   --name `"" + $VnetName + "`""
        $CheckStr = $CheckStr + " ```r`n   --resource-group `"" + $ResourceGroup + "`""
        $CheckStr = $CheckStr + " ```r`n   --query name"
        $CheckStr = $CheckStr + " ```r`n   --output tsv)"

        Write-Log -Message $CheckStr -LogFile $This.LogFile -Color "green"

        $Name = $Null
        Invoke-Expression $CheckStr

        If ($Name -eq $VnetName) {
            Write-Log -Message "Azure Vnet $VnetName already exists" -LogFile $This.LogFile -Color "yellow"
        }
        Else {        
            Write-Log -Message "Creating Azure Vnet $VnetName ..." -LogFile $This.LogFile -Color "green"

            $CommandStr = $This.BuildCommand($False)        

            Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"

            $CommandStr = $CommandStr + "`r`n `$ErrorFound = `$?"

            $ErrorFound = $False
            Invoke-Expression $CommandStr

            If (!$ErrorFound) {
                Throw("Error creating Azure Vnet $($VnetName)")
            }
            Else {
                Write-Log -Message "Azure Vnet $($VnetName) has been successfully created" -LogFile $This.LogFile -Color "green"
            }            
        }  

        Return $Variables
    }
}

Class AzCommandNetworkVnetSubnetCreate : AzCommand {

    AzCommandNetworkVnetSubnetCreate([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $Params, $LogFile) {     
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        $This.ReplaceParamsTokens($Variables)
        
        $SubnetName = $This.FindParamValueByName("name")
        $ResourceGroup = $This.FindParamValueByName("resource-group")
        $VnetName = $This.FindParamValueByName("vnet-name")

        $CheckStr = "`r`n`$Name = `$(az network vnet subnet show"
        $CheckStr = $CheckStr + " ```r`n   --name `"" + $SubnetName + "`""
        $CheckStr = $CheckStr + " ```r`n   --resource-group `"" + $ResourceGroup + "`""
        $CheckStr = $CheckStr + " ```r`n   --vnet-name `"" + $VnetName + "`""
        $CheckStr = $CheckStr + " ```r`n   --query name"
        $CheckStr = $CheckStr + " ```r`n   --output tsv)"

        Write-Log -Message $CheckStr -LogFile $This.LogFile -Color "green"

        $Name = $Null
        Invoke-Expression $CheckStr

        If ($Name -eq $SubnetName) {
            Write-Log -Message "Azure Vnet Subnet $SubnetName already exists" -LogFile $This.LogFile -Color "yellow"
        }
        Else {        
            Write-Log -Message "Creating Azure Vnet Subnet $SubnetName ..." -LogFile $This.LogFile -Color "green"

            $CommandStr = $This.BuildCommand($False)        

            Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"
        
            $CommandStr = $CommandStr + "`r`n `$ErrorFound = `$?"

            $ErrorFound = $False
            Invoke-Expression $CommandStr
    
            If (!$ErrorFound) {
                Throw("Error creating Azure Vnet Subnet $($SubnetName)")
            }
            Else {
                Write-Log -Message "Azure Vnet Subnet $($SubnetName) has been successfully created" -LogFile $This.LogFile -Color "green"
            }            
        }  

        Return $Variables
    }
}

Class AzCommandAdSpCreateForRbac : AzCommand {

    AzCommandAdSpCreateForRbac([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        Return $Variables
    }
}

Class AzCommandKevaultSecretSet : AzCommand {

    AzCommandKevaultSecretSet([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $Params, $LogFile) { 
    }

    [Hashtable] Execute([Hashtable] $Variables) {$This.ReplaceParamsTokens($Variables)
        $CommandStr = $This.BuildCommand($False)        

        Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"
        
        $CommandStr = $CommandStr + "`r`n `$ErrorFound = `$?"

        $ErrorFound = $False
        Invoke-Expression $CommandStr

        If (!$ErrorFound) {
            Throw("Error setting Keyvault Secret")
        }
        Else {
            Write-Log -Message "Azure Keyvault Secret has been successfully set" -LogFile $This.LogFile -Color "green"
        }  

        Return $Variables
    }
}

Class AzCommandAcrCreate : AzCommand {

    AzCommandAcrCreate([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        $This.ReplaceParamsTokens($Variables)
        
        $AcrName = $This.FindParamValueByName("name")
        $ResourceGroup = $This.FindParamValueByName("resource-group")

        $CheckStr = "`r`n`$Name = `$(az acr show"
        $CheckStr = $CheckStr + " ```r`n   --name `"" + $AcrName + "`""
        $CheckStr = $CheckStr + " ```r`n   --resource-group `"" + $ResourceGroup + "`""
        $CheckStr = $CheckStr + " ```r`n   --query name"
        $CheckStr = $CheckStr + " ```r`n   --output tsv)"

        Write-Log -Message $CheckStr -LogFile $This.LogFile -Color "green"

        $Name = $Null
        Invoke-Expression $CheckStr

        If ($Name -eq $AcrName) {
            Write-Log -Message "Azure Container Registry $AcrName already exists" -LogFile $This.LogFile -Color "yellow"
        }
        Else {        
            Write-Log -Message "Creating Azure Container Registry $AcrName ..." -LogFile $This.LogFile -Color "green"

            $CommandStr = $This.BuildCommand($False)        

            Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"
        
            $CommandStr = $CommandStr + "`r`n `$ErrorFound = `$?"

            $ErrorFound = $False
            Invoke-Expression $CommandStr

            If (!$ErrorFound) {
                Throw("Error creating Azure Container Registry $($AcrName)")
            }
            Else {
                Write-Log -Message "Azure Container Registry $($AcrName) has been successfully created" -LogFile $This.LogFile -Color "green"
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

Class AzCommandServicebusNamespaceCreate : AzCommand {

    AzCommandServicebusNamespaceCreate([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $Params, $LogFile) {  
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        $This.ReplaceParamsTokens($Variables)
        
        $SbName = $This.FindParamValueByName("name")

        $CheckStr = "`r`n`$Check = `$(az servicebus namespace exists"
        $CheckStr = $CheckStr + " ```r`n   --name `"" + $SbName + "`""
        $CheckStr = $CheckStr + " ```r`n   --query `"nameAvailable`""
        $CheckStr = $CheckStr + " ```r`n   --output `"tsv`")"

        Write-Log -Message $CheckStr -LogFile $This.LogFile -Color "green"

        $Check = $False
        Invoke-Expression $CheckStr

        If ("false" -eq $Check) {
            Write-Log -Message "Azure Service Bus $SbName already exists" -LogFile $This.LogFile -Color "yellow"
        }
        Else {        
            Write-Log -Message "Creating Azure Service Bus $SbName ..." -LogFile $This.LogFile -Color "green"

            $CommandStr = $This.BuildCommand($False)        

            Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"
        
            $CommandStr = $CommandStr + "`r`n `$ErrorFound = `$?"

            $ErrorFound = $False
            Invoke-Expression $CommandStr
    
            If (!$ErrorFound) {
                Throw("Error creating Azure Service Bus $($SbName)")
            }
            Else {
                Write-Log -Message "Azure Service Bus $($SbName) has been successfully created" -LogFile $This.LogFile -Color "green"
            }            
        }
        Return $Variables
    }
}

Class AzCommandCosmosdbCreate : AzCommand {

    AzCommandCosmosdbCreate([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        $This.ReplaceParamsTokens($Variables)
        
        $CosmosDbName = $This.FindParamValueByName("name")

        $CheckStr = "`r`n`$Check = `$(az cosmosdb check-name-exists"
        $CheckStr = $CheckStr + " ```r`n   --name `"" + $CosmosDbName + "`")"

        Write-Log -Message $CheckStr -LogFile $This.LogFile -Color "green"

        $Check = $False
        Invoke-Expression $CheckStr

        If ("true" -eq $Check) {
            Write-Log -Message "Azure Cosmo DB $CosmosDbName already exists" -LogFile $This.LogFile -Color "yellow"
        }
        Else {        
            Write-Log -Message "Creating Azure Cosmo DB $CosmosDbName ..." -LogFile $This.LogFile -Color "green"

            $CommandStr = $This.BuildCommand($False)        

            Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"
        
            $CommandStr = $CommandStr + "`r`n `$ErrorFound = `$?"

            $ErrorFound = $False
            Invoke-Expression $CommandStr

            If (!$ErrorFound) {
                Throw("Error creating Azure Cosmo DB $($CosmosDbName)")
            }
            Else {
                Write-Log -Message "Azure Cosmo DB $($CosmosDbName) has been successfully created" -LogFile $This.LogFile -Color "green"
            }            
        }  
        Return $Variables
    }
}

Class AzCommandApimCreate : AzCommand {

    AzCommandApimCreate([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $Params, $LogFile) {
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        $This.ReplaceParamsTokens($Variables)
        
        $ApimName = $This.FindParamValueByName("name")
        $ResourceGroup = $This.FindParamValueByName("resource-group")

        $CheckStr = "`r`n`$Name = `$(az apim show"
        $CheckStr = $CheckStr + " ```r`n   --name `"" + $ApimName + "`""
        $CheckStr = $CheckStr + " ```r`n   --resource-group `"" + $ResourceGroup + "`""
        $CheckStr = $CheckStr + " ```r`n   --query name"
        $CheckStr = $CheckStr + " ```r`n   --output tsv)"

        Write-Log -Message $CheckStr -LogFile $This.LogFile -Color "green"

        $Name = $Null
        Invoke-Expression $CheckStr

        If ($Name -eq $ApimName) {
            Write-Log -Message "Azure Api Management $ApimName already exists" -LogFile $This.LogFile -Color "yellow"
        }
        Else {        
            Write-Log -Message "Creating Azure Api Management $ApimName ..." -LogFile $This.LogFile -Color "green"

            $CommandStr = $This.BuildCommand($False)        

            Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"
        
            $CommandStr = $CommandStr + "`r`n `$ErrorFound = `$?"

            $ErrorFound = $False
            Invoke-Expression $CommandStr

            If (!$ErrorFound) {
                Throw("Error creating Azure Api Management $($ApimName)")
            }
            Else {
                Write-Log -Message "Azure Api Management $($ApimName) has been successfully created" -LogFile $This.LogFile -Color "green"
            }              
        }  

        Return $Variables
    }
}

Class AzCommandResourceUpdate : AzCommand {

    AzCommandResourceUpdate([String] $Type, [String] $Name, [String] $Output, [AzParam[]] $Params, [String] $LogFile) : base ($Type, $Name, $Output, $Params, $LogFile) {
      
    }

    [Hashtable] Execute([Hashtable] $Variables) {
        $This.ReplaceParamsTokens($Variables)

        $CommandStr = $This.BuildCommand($False)      

        Write-Log -Message $CommandStr -LogFile $This.LogFile -Color "green"
        
        $CommandStr = $CommandStr + "`r`n `$ErrorFound = `$?"

        $ErrorFound = $False
        Invoke-Expression $CommandStr

        If (!$ErrorFound) {
            Throw("Error updating resource")
        }
        Else {
            Write-Log -Message "Azure Resource has been successfully updated" -LogFile $This.LogFile -Color "green"
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
