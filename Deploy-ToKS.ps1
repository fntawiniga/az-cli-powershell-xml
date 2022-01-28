<#
.SYNOPSIS
This script will deploy to Azure using Powershell scripts running Azure CLI

.DESCRIPTION
The script calls Deploy-ToAzureCommon.ps1 Powershell script to create the following components if they do not exists
    A message bus (Azure Service Bus)
    An event store (Eventstore)
    A persistent store (Azure Cosmos DB)

The script calls Deploy-ToAzureService.ps1 Powershell script to create the following components if they do not exists
    The Licence API service/app in Azure Container Instance
    The Licence Command Processor service/app in Azure Container Instance
    The Licence Query Processor service/app in Azure Container Instance
    The Licence Store Query Manager service/app in Azure Container Instance
Sample execution command

  .\Deploy-ToKS.ps1 -Subscription <Subscription> -EventStorePwdFilename "C:\Dev\Secrets\<EventStore>.txt" -OutputFolder "C:\Dev\Temp"
#>

Param
(
    [String] $Subscription = "",
    [String] $OutputFolder = $(Throw "Output Folder (-OutputFolder) Required"),
    [String] $EventStorePwdFilename = $Null,
    [Boolean] $AuthenticationEnabled = $False,
    [String] $Org = "cnsc",  
    [String] $Namespace = "svc",   
    [String] $Service = "lic",   
    [String] $Environment = "dev", #Possible values dev, tst, stg, prd
    [String] $Instance = "003",   
    [Boolean] $SkipBuild = $False,
    [Boolean] $CleanResources = $False
)

Try {

    $AzVersion  = (Az version)
    Write-Host "Azure CLI version       = $AzVersion" -ForegroundColor Green
    Write-Host "AzUsername              = $AzUsername" -ForegroundColor Green
    Write-Host "Subscription            = $Subscription" -ForegroundColor Green
    Write-Host "EventStorePwdFilename   = $EventStorePwdFilename" -ForegroundColor Green
    Write-Host "Org                     = $Org" -ForegroundColor Green
    Write-Host "Namespace               = $Namespace" -ForegroundColor Green
    Write-Host "Service                 = $Service" -ForegroundColor Green
    Write-Host "Environment             = $Environment" -ForegroundColor Green
    Write-Host "Instance                = $Instance" -ForegroundColor Green
    Write-Host "SkipBuild               = $SkipBuild" -ForegroundColor Green
    Write-Host "CleanResources          = $CleanResources" -ForegroundColor Green
    Write-Host "OutputFolder            = $OutputFolder" -ForegroundColor Green

    $Location = "canadaeast"

    $AzureCosmoDbServerVersion = "4.0"
    $AzureCosmoDbRegionName = "Canada Central"

    $ResourceGroup = "rg-$($Org)-$($Namespace)-$($Environment)-$($Instance)"
    
    $KeyVault = "kv-$($Org)-$($Namespace)-$($Environment)-$($Instance)"
    

    $AzureServiceBusName = "sb-$($Org)-$($Namespace)-$($Environment)"
    $AzureCosmosDbName = "cosmos-$($Org)-$($Namespace)-persistentstore-$($Environment)" 

    #$EventStoreAciName = "ci-$($Org)-$($Namespace)-$($Common)-eventstore-$($Environment)-$($Instance)"
    
    $AksName = "ks-$($Org)-$($Namespace)-$($Environment)-$($Instance)"
    $VnetName = "vnet-$($Environment)-$($Location)-$($Instance)"
    $AksSubnetName = "snet-aks-$($Environment)-$($Location)-$($Instance)"
    $ApimSubnetName = "snet-apim-$($Environment)-$($Location)-$($Instance)"

    $SpName = "sp-aks-pim-$($Environment)-$($Instance)"

    If("" -ne $Subscription) {
        az account set --subscription $Subscription
    }

    # Creation of Resource Group
    $Check = az group exists --name $ResourceGroup 
    If ($Check -eq $True) {
        Write-Host "Resource Group $($ResourceGroup) already exists" -ForegroundColor Yellow
    }
    Else {        
        Write-Host "Creating Resource Group $($ResourceGroup) ..." -ForegroundColor Green
        az group create `
            --location $Location `
            --name $ResourceGroup `
            --output table
        Write-Host "Resource Group $($ResourceGroup) has been created in $($Location)" -ForegroundColor Green
    }  
    
    #Create Keyvault        
    $Check = $(az keyvault show  `
                --resource-group $ResourceGroup `
                --name $KeyVault `
                --output table)

    If($Null -ne $Check) {
        Write-Host "Azure KeyVault $KeyVault already exists" -ForegroundColor Yellow
    }
    Else {
        Write-Host "Creating Azure KeyVault $KeyVault ..." -ForegroundColor Green
        
        az keyvault create `
            --resource-group $ResourceGroup `
            --location $Location `
            --name $KeyVault `
            --output table

        Write-Host "Azure KeyVault $KeyVault has been created" -ForegroundColor Green
    }

    # Creation of Azure Vnet
    $Check = $(az network vnet show  `
                --resource-group $ResourceGroup `
                --name $VnetName `
                --output table)

    If($Null -ne $Check) {
        Write-Host "Azure Vnet $VnetName already exists" -ForegroundColor Yellow
    }
    Else {
        Write-Host "Creating Azure Vnet $VnetName ..." -ForegroundColor Green
        
        az network vnet create `
            --resource-group $ResourceGroup `
            --location $Location `
            --name $VnetName `
            --address-prefixes 10.10.0.0/16 `
            --output table

        Write-Host "Azure Vnet $VnetName has been created" -ForegroundColor Green
    }

    # Creation of Azure Aks subnet
    $Check = $(az network vnet subnet show  `
        --resource-group $ResourceGroup `
        --name $AksSubnetName `
        --vnet-name $VnetName)

    If($Null -ne $Check) {
        Write-Host "Azure Vnet Subnet $AksSubnetName already exists" -ForegroundColor Yellow
    }
    Else {
        Write-Host "Creating Azure Vnet Subnet $AksSubnetName ..." -ForegroundColor Green
        
        az network vnet subnet  create `
            --resource-group $ResourceGroup `
            --name $AksSubnetName `
            --vnet-name $VnetName `
            --address-prefixes 10.10.1.0/24 `
            --output table

        Write-Host "Azure Vnet Subnet $AksSubnetName has been created" -ForegroundColor Green
    }

    # Creation of Azure Apim subnet
    $Check = $(az network vnet subnet show  `
        --resource-group $ResourceGroup `
        --name $ApimSubnetName `
        --vnet-name $VnetName `
        --output table)

    If($Null -ne $Check) {
        Write-Host "Azure Vnet Subnet $ApimSubnetName already exists" -ForegroundColor Yellow
    }
    Else {
        Write-Host "Creating Azure Vnet Subnet $ApimSubnetName ..." -ForegroundColor Green
        
        az network vnet subnet  create `
            --resource-group $ResourceGroup `
            --name $ApimSubnetName `
            --vnet-name $VnetName `
            --address-prefixes 10.10.2.0/24 `
            --output table

        Write-Host "Azure Vnet Subnet $ApimSubnetName has been created" -ForegroundColor Green
    }

    $AppId = $(az ad sp list `
                --filter "displayName eq '$($SpName)'" `
                --query '[].appId' `
                --output tsv)

    If($Null -ne $AppId) {
        Write-Host "Azure Service Principal $SpName already exists" -ForegroundColor Yellow
    }
    Else {
        Write-Host "Creating Azure Service Principal $SpName ..." -ForegroundColor Green
        
        $VnetId = $(az network vnet show `
                    --resource-group $ResourceGroup `
                    --name $VnetName `
                    --query id `
                    --output tsv)

        $SpPassword = $(az ad sp create-for-rbac `
                        --name $SpName `
                        --role Contributor `
                        --scopes $VnetId `
                        --query password `
                        --output tsv)

        $AppId = $(az ad sp list `
                    --filter "displayName eq '$($SpName)'" `
                    --query '[].appId' `
                    --output tsv)

        #Update Keyvault Secrets
        az keyvault secret set `
            --name $SpName `
            --vault-name $KeyVault `
            --value $SpPassword `
            --output table

        Write-Host "Azure Service Principal $SpName has been created" -ForegroundColor Green
    }

    
    $AcrName = "cr$($Org)$($Namespace)$($Environment)$($Instance)"

    #Create Azure Container Registry
    $Check = $(az acr show  `
                --resource-group $ResourceGroup `
                --name $AcrName `
                --output table)

    If($Null -ne $Check) {
        Write-Host "Azure Container Registry $($AcrName) already exists" -ForegroundColor Yellow
    }
    Else {
        Write-Host "Creating Azure Container Registry $($AcrName) ..." -ForegroundColor Green
        az acr create `
            --location $Location `
            --name $AcrName `
            --resource-group $ResourceGroup  `
            --sku Standard `
            --output table
        Write-Host "Azure Container Registry $($AcrName) created" -ForegroundColor Green
    }     

    #Enable Admin in ACR
    Write-Host "Enabling Admin for Azure Container Registry $($AcrName) ..." -ForegroundColor Green
    az acr update `
        --name $AcrName `
        --resource-group $ResourceGroup `
        --admin-enabled true `
        --output table

    <# Write-Host "Azure Container Registry $($AcrName) admin enabled" -ForegroundColor Green

    $AcrCreds = $(az acr credential show `
                    --name $AcrName `
                    --resource-group $ResourceGroup)  | ConvertFrom-Json

    $RegistryUsername = $AcrCreds.username
    $RegistryPassword = $AcrCreds.passwords.value[0]

    #Update Keyvault Secrets
    az keyvault secret set `
        --name $RegistryUsername `
        --vault-name $KeyVault `
        --value $RegistryPassword `
        --output table

    # Create Service KS 
   
    $Check = az aks show  --resource-group $ResourceGroup --name $AksName
    If($Null -ne $Check) {
        Write-Host "Azure Kubernates Service $($AksName) already exists" -ForegroundColor Yellow
    }
    Else {
        $AksSubnetId = $(az network vnet subnet show `
                            --resource-group $ResourceGroup `
                            --vnet-name $VnetName `
                            --name $AksSubnetName `
                            --query id `
                            --output tsv)

        $AksLatestVersion =  $(az aks get-versions `
                                --location $Location `
                                --query 'orchestrators[-1].orchestratorVersion' `
                                --output tsv)

        $AppId = $(az ad sp list `
                    --filter "displayName eq '$($SpName)'" `
                    --query '[].appId' `
                    --output tsv)


        $SpPassword = $(az keyvault secret show `
                            --name $SpName `
                            --vault-name $KeyVault `
                            --query "value")

        Write-Host "Azure Kubernates Service Latest version used is $($AksLatestVersion)" -ForegroundColor Green

        Write-Host "Creating Azure Kubernates Service $($AksName) ..." -ForegroundColor Green
        
        $AksSshFilename = "$($OutputFolder)\aks-ssh-service"
        Write-Output "y" | ssh-keygen -b 2048 -t rsa -f $AksSshFilename -q -N """"
        Write-Host "SSH Key $($AksSshFilename) has been successfully created" -ForegroundColor Green
        
        az aks create --resource-group $ResourceGroup `
            --name $AksName `
            --vm-set-type VirtualMachineScaleSets `
            --node-count 1 `
            --service-principal $AppId `
            --client-secret $SpPassword `
            --load-balancer-sku standard `
            --location $Location `
            --kubernetes-version $AksLatestVersion `
            --network-plugin azure `
            --vnet-subnet-id $AksSubnetId `
            --service-cidr 10.0.0.0/16 `
            --dns-service-ip 10.0.0.10 `
            --docker-bridge-address 172.17.0.1/16 `
            --node-vm-size "Standard_B2s" `
            --enable-addons monitoring `
            --attach-acr $AcrName `
            --ssh-key-value "$($AksSshFilename).pub" `
            --output table
        # Issue with --generate-ssh-keys bug in AVD space in windows user name https://github.com/Azure/azure-cli/issues/6142   

        Write-Host "Azure Kubernates Service $($AksName) has been created" -ForegroundColor Green
    }

    az aks get-credentials `
        --resource-group $ResourceGroup `
        --name $AksName `
        --output table
   
    # Create an Azure Service Bus
    $Check  = $(az servicebus namespace exists `
                    --name $AzureServiceBusName) | ConvertFrom-Json

    If ($Check.nameAvailable -eq $False) {
        Write-Host "Azure Service Bus $($AzureServiceBusName) already exists" -ForegroundColor Yellow
    }
    Else {
        Write-Host "Creating Azure Service Bus $($AzureServiceBusName) ..." -ForegroundColor Green
        az servicebus namespace create `
            --name $AzureServiceBusName `
            --resource-group $ResourceGroup `
            --location $Location `
            --sku Standard `
            --output table

        Write-Host "Azure Service Bus $($AzureCosmosDbName) has been created" -ForegroundColor Green
    }      
    
    # Create a Cosmos account for MongoDb API
    $Check  = $(az cosmosdb check-name-exists `
                    --name $AzureCosmosDbName)

    If ($Check -eq $True) {
        Write-Host "Azure Cosmo DB $($AzureCosmosDbName) already exists" -ForegroundColor Yellow
    }
    Else {
        Write-Host "Creating Azure Cosmo DB $($AzureCosmosDbName) ..." -ForegroundColor Green
        az cosmosdb create `
            --name $AzureCosmosDbName `
            --resource-group $ResourceGroup `
            --kind MongoDB `
            --default-consistency-level Eventual `
            --enable-automatic-failover true `
            --server-version $AzureCosmoDbServerVersion `
            --locations regionName=$AzureCosmoDbRegionName failoverPriority=0 isZoneRedundant=False `
            --output table

        Write-Host "Azure Cosmo DB $($AzureCosmosDbName) has been created" -ForegroundColor Green
    }        

    #Retrieve Azure Service Bus Password    
    $AzureServiceBusKey = (az servicebus namespace authorization-rule keys list --resource-group $ResourceGroup --name RootManageSharedAccessKey --namespace-name $AzureServiceBusName)   | ConvertFrom-Json
    $azureServiceBusSettingsSharedAccessKey = $AzureServiceBusKey.primaryKey
    
    az keyvault secret set `
        --name "azureServiceBusSettingsSharedAccessKey" `
        --vault-name $KeyVault `
        --value $azureServiceBusSettingsSharedAccessKey `
        --output table
    
    Write-Host "Updated Azure KeyVault $KeyVault azureServiceBusSettingsSharedAccessKey secret" -ForegroundColor Green
        
    #Retrieve Event Store Password
    $EventStorePassword = ""
    If($EventStorePwdFilename) {
        $SecurePassword = Get-Content $EventStorePwdFilename | ConvertTo-SecureString
        $Bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
        $EventStorePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($Bstr)
    }
    Else {
        Write-Host "Please Enter Password for Event Store (Eventstore)"
        $EventStorePassword = Read-Host -AssecureString
    }

    az keyvault secret set `
        --name "eventStoreSettingsPassword" `
        --vault-name $KeyVault `
        --value $EventStorePassword `
        --output table
    
    Write-Host "Updated Azure KeyVault $KeyVault eventStoreSettingsPassword secret" -ForegroundColor Green
     
    #Retrieve Azure Cosmos DB Password
    $CosmosDbKeys = $(az cosmosdb keys list `
                        --name $AzureCosmosDbName `
                        --resource-group $ResourceGroup)   | ConvertFrom-Json

    $PersistentStorePassword = $CosmosDbKeys.primaryMasterKey
    
    az keyvault secret set `
        --name "mongoDbSettingsPassword" `
        --vault-name $KeyVault `
        --value $PersistentStorePassword `
        --output table
    
    Write-Host "Updated Azure KeyVault $KeyVault mongoDbSettingsPassword secret" -ForegroundColor Green  
 #>
} 
Catch {
    Write-Host "Unidentified Error Happened" -ForegroundColor Red
    Write-Host $Error[0].Exception  -ForegroundColor Red
}