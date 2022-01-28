<#

.SYNOPSIS
	This script is used to process CNSC scripts

.DESCRIPTION
 
	Example: 
		.\ScriptBase.ps1 -MsXrmToolingModule "..\Powershell\Microsoft.Xrm.Tooling.CrmConnector.Powershell.dll" -CnscXrmToolingModule "..\Powershell\Cnsc.Cms.Powershell.dll" -CrmUserName "CRMAdmin" -CrmPwdFilename "..\CRMAdmin.txt" -CrmServerUrl "https://crm2015.npl.cnsc.gc.ca" -CrmOrgName "DEVCOI4" -CrmAdminUserFullName "CRM Admin" -Script ".\Deploy_2.0.0.1_1.xml"

.NOTES  
    File Name  : ScriptBase.ps1  
	Version	   : 3.15.1.0
    Requires   : 
	- Powershell Version 3 and above  
	- Cnsc.Cms.Powershell.dll  Module
	- Microsoft.Xrm.Tooling.CrmConnector.Powershell.dll Module
	- ScriptBase.ps1 in the same directory
#>

param
(
    #required params
	[string]$OutputFolder = $(throw "Output folder (-OutputFolder) Required"),
	[string]$Script = $(throw "XML Script (-Script) Required"),
	[string]$StopOnError = $True
)

############## PROCESS XML DATA ##############
<#
NAME
  Get-CommandParam
 
SYNTAX
  Get-CommandParam [[-Params] <Array>]
 
PARAMETERS
  -Params <Array> Associative array with key and value
INPUTS
  None
 
OUTPUTS
  String
 
ALIASES
  None
 
REMARKS
  Get command param value
#>
Function Get-CommandParam($Params){
	$Result = @{}
	Foreach ($Param in $Params){
		$ParamName = $Param.name.ToLower()
		$Result[$ParamName] = Replace-SpecialChars($Param.value)
	}
	
	Return $Result
}

Function Convert-StringToArray($String){
	$StringArray = $String  -split ","
	$Result = @()
	Foreach ($Item in $StringArray){
		$Result += $Item.Trim()
	}
	Return [String[]]$Result
}

<#
NAME
  Write-Log
 
SYNTAX
  Write-Log [[-InputString] <String>]
 
PARAMETERS
  -Message <String> Message to log
  -LogFile <String> Log File path
  -Color   <String> Color on the console
  -AddDate <Boolean> Flag to check if current date can be added
INPUTS
  None
 
OUTPUTS
  None
 
ALIASES
  None
 
REMARKS
  Save log record
#>
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

<#
NAME
  Replace-SpecialChars
 
SYNTAX
  Replace-SpecialChars [[-InputString] <String>]
 
PARAMETERS
  -InputString <String> Input string
 
INPUTS
  None
 
OUTPUTS
  String
 
ALIASES
  None
 
REMARKS
  Replaces html special characters in xml with their true value
#>
function Replace-SpecialChars($InputString) {
    $InputString = ($InputString -replace "&amp;", "&")
    $InputString = ($InputString -replace "&quot;", """")

    Return $InputString
}

$Tempo = Get-Date -format "yyyyMMdd-hhmm"
$ScriptBasename = [System.IO.Path]::GetFileName($Script)
$LogFile = "$OutputFolder\Log-$ScriptBasename-$Tempo.txt"
$ErrorOccured = $False

$Data = Get-Content $Script
#$Data = ($Data -replace "&", "&amp;")
$XmlDoc = [xml]($Data)

Foreach ($ScriptCommand in $XmlDoc.scriptCommands.ScriptCommand){
	Try {
		$Time = Get-Date -format "yyyy-MM-dd hh:mm:ss"
		
		$CommandType = $ScriptCommand.type.ToLower();
		Switch ($CommandType){		
			"append-crmfakerefdatarecords" {
				$Params = Get-CommandParam $ScriptCommand.Param
			
				$EntityLogicalName = $Params["entitylogicalname"]
				$Fields = Convert-StringToArray($Params["fields"])	
				$XmlFilePath = $Params["xmlfilepath"]
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	EntityLogicalName = $EntityLogicalName" -LogFile $LogFile
				Write-Log -Message "	Fields = $Fields" -LogFile $LogFile
				Write-Log -Message "	XmlFilePath = $XmlFilePath" -LogFile $LogFile
				
				$Result = Append-CrmFakeRefDataRecords -CrmConn $Conn -EntityLogicalName $EntityLogicalName -Fields $Fields -XmlFilePath $XmlFilePath
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"associate-crmrecords" { 
				$Params = Get-CommandParam $ScriptCommand.Param
			
				$CurrentEntityName = $Params["currententityname"]
				$CurrentRecordName = $Params["currentrecordname"]
				$OtherEntityName = $Params["otherentityname"]
				$OtherRecordNames = Convert-StringToArray($Params["otherrecordnames"])
				$RelationshipName = $Params["relationshipname"]
				$Append = $Params["append"] -eq "1"
				$LinkEntityName = $Params["linkentityname"]
				$LinkEntityAttribute = $Params["linkentityattribute"]
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	CurrentEntityName = $CurrentEntityName" -LogFile $LogFile
				Write-Log -Message "	CurrentRecordName = $CurrentRecordName" -LogFile $LogFile
				Write-Log -Message "	OtherEntityName = $OtherEntityName" -LogFile $LogFile
				Write-Log -Message "	OtherRecordNames = $OtherRecordNames" -LogFile $LogFile
				Write-Log -Message "	RelationshipName = $RelationshipName" -LogFile $LogFile
				Write-Log -Message "    Append = $Append" -LogFile $LogFile
				Write-Log -Message "	LinkEntityName = $LinkEntityName" -LogFile $LogFile
				Write-Log -Message "	LinkEntityAttribute = $LinkEntityAttribute" -LogFile $LogFile
				
				$Result = Associate-CrmRecords -CrmConn $Conn -CurrentEntityName $CurrentEntityName -CurrentRecordName $CurrentRecordName -OtherEntityName $OtherEntityName -OtherRecordNames $OtherRecordNames -RelationshipName $RelationshipName -Append $Append -LinkEntityName $LinkEntityName -LinkEntityAttribute $LinkEntityAttribute
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"compare-crmmetadata" {
				If($ConnSource -and $Conn) {
					$Params = Get-CommandParam $ScriptCommand.Param
					$CrmSolutionName = $Params["crmsolutionname"]
					$SolutionPackager = $Params["solutionpackager"]
					$BeyondCompare = $Params["beyondcompare"]
					$BeyondCompareScript = $Params["beyondcomparescript"]	
					$RenameSDKSteps = $Params["renamesdksteps"] -ne "0"				
					
					Write-Log -Message "$CommandType" -LogFile $LogFile
					Write-Log -Message "	CrmSolutionName = $CrmSolutionName" -LogFile $LogFile
					Write-Log -Message "	SolutionPackager  = $SolutionPackager" -LogFile $LogFile
					Write-Log -Message "	BeyondCompare  = $BeyondCompare" -LogFile $LogFile
					Write-Log -Message "	BeyondCompareScript  = $BeyondCompareScript" -LogFile $LogFile
					
					#Export Source Solution
					Write-Log -Message "CrmOrgNameExport Source Solution $CrmSolutionName from $CrmSourceServerUrl/$CrmSourceOrgName..." -Color "green"	-AddDate $True

					$ManagedSolutionSource = Export-CrmSolution -CrmConn $ConnSource -IncludeVersionInName $True  -Managed $False -OutputFolder $OutputFolder -FileName $CrmSolutionName -UniqueSolutionName $CrmSolutionName 

					Rename-Item "$OutputFolder\$ManagedSolutionSource" "$OutputFolder\$CrmSourceOrgName-$Tempo-$ManagedSolutionSource"
					$PackageFileSource = "$OutputFolder\$CrmSourceOrgName-$Tempo-$ManagedSolutionSource"

					$PackageFolderSource = $PackageFileSource.Substring(0, $PackageFileSource.LastIndexOf('.'))

					#Extract Source Solution
					Write-Log -Message "Extract Source Solution $PackageFileSource..." -Color "green"
					$ExtractOuputSource = & "$SolutionPackager" /action:Extract /zipfile:"$PackageFileSource" /folder:"$PackageFolderSource" /errorlevel:Info /allowWrite:Yes /allowDelete:Yes 

					If($RenameSDKSteps) {
						#Renames Source SDK Message Processing steps
						Write-Log -Message "Renaming Source SDK Message Processing steps" -Color "green"
						$Result = Rename-SolutionPackageSdkMessageProcessingSteps -DirectoryPath "$PackageFolderSource\SdkMessageProcessingSteps" -Overwrite $True -RemoveOutOfBox $True -IncludeGuidInFileName $True

						#Renames Source Dashboards
						Write-Log -Message "Renaming Source Dashboards" -Color "green"
						$Result = Rename-SolutionPackageDashboards -DirectoryPath "$PackageFolderSource\Dashboards" -Overwrite $True -IncludeGuidInFileName $True
					}

					#Export Target Solution
					Write-Log -Message "Export Target Solution $CrmSolutionName from $CrmServerUrl/$CrmOrgName..." -Color "green"	-AddDate $True

					$ManagedSolutionTarget = Export-CrmSolution -CrmConn $Conn -IncludeVersionInName $True  -Managed $False -OutputFolder $OutputFolder -FileName $CrmSolutionName -UniqueSolutionName $CrmSolutionName 

					Rename-Item "$OutputFolder\$ManagedSolutionTarget" "$OutputFolder\$CrmOrgName-$Tempo-$ManagedSolutionTarget"
					$PackageFileTarget = "$OutputFolder\$CrmOrgName-$Tempo-$ManagedSolutionTarget"

					$PackageFolderTarget = $PackageFileTarget.Substring(0, $PackageFileTarget.LastIndexOf('.')) 

					#Extract Target Solution
					Write-Log -Message "Extract Target Solution $PackageFileTarget..." -Color "green"	-AddDate $True
					$ExtractOuputTarget = & "$SolutionPackager" /action:Extract /zipfile:"$PackageFileTarget" /folder:"$PackageFolderTarget" /errorlevel:Info /allowWrite:Yes /allowDelete:Yes 

					If($RenameSDKSteps) {
						#Renames Target SDK Message Processing steps
						Write-Log -Message "Renaming Target SDK Message Processing steps" -Color "green"	-AddDate $True
						$Result = Rename-SolutionPackageSdkMessageProcessingSteps -DirectoryPath "$PackageFolderTarget\SdkMessageProcessingSteps" -Overwrite $True -RemoveOutOfBox $True -IncludeGuidInFileName $True

						#Renames Target Dashboards
						Write-Log -Message "Renaming Target Dashboards" -Color "green"
						$Result = Rename-SolutionPackageDashboards -DirectoryPath "$PackageFolderTarget\Dashboards" -Overwrite $True -IncludeGuidInFileName $True
					}
					
					#Compare using Beyond Compare 2
					Write-Log -Message "Compare $PackageFolderSource folder and $PackageFolderTarget folder using Beyond Compare 2..." -Color "green"	-AddDate $True

					$ReportFile = "$OutputFolder\ReportMetadataComparison-$CrmSourceOrgName-$CrmOrgName-$Tempo.txt"

					& $BeyondCompare $BeyondCompare2ScriptFile  $PackageFolderSource $PackageFolderTarget $ReportFile
					
					Write-Log -Message "The report file $ReportFile has been successfully generated" -Color "green"	-AddDate $True
				}
				Else {
					 Throw "Please check your CRM Source & Target environmenents connection parameters" 
				}
				break
			}
			"compare-crmsystemsettings" { 	
				If($ConnSource -and $Conn) {
					$Params = Get-CommandParam $ScriptCommand.Param
					$IgnoredAttributes = Convert-StringToArray($Params["ignoredattributes"])
					$DisplayMatch = $Params["displaymatch"] -ne "0"
					
					Write-Log -Message "$CommandType" -LogFile $LogFile
					Write-Log -Message "	IgnoredAttributes = $IgnoredAttributes" -LogFile $LogFile
					Write-Log -Message "	DisplayMatch  = $DisplayMatch" -LogFile $LogFile
					
					$Result = Compare-CrmSystemSettings -CrmConnSource $ConnSource -CrmConnTarget $Conn  -IgnoredAttributes $IgnoredAttributes -DisplayMatch $DisplayMatch
					Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				}
				Else {
					 Throw "Please check your CRM Source & Target environmenents connection parameters" 
				}
				break
			}
			"export-crmaccessteamtemplates" { 
				$Params = Get-CommandParam $ScriptCommand.Param
				
				$OutputFolder = $Params["outputfolder"]
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	OutputFolder = $OutputFolder" -LogFile $LogFile
				
				$Result = Export-CrmAccessTeamTemplates -CrmConn $Conn -OutputFolder $OutputFolder
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"export-crmsolution" { 
				$Params = Get-CommandParam $ScriptCommand.Param
				
				$FileName = $Params["filename"]
				$OutputFolder = $Params["outputfolder"]
				$UniqueSolutionName = $Params["uniquesolutionname"]
				$Managed = $Params["managed"] -ne "0"
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	FileName = $FileName" -LogFile $LogFile
				Write-Log -Message "	OutputFolder = $OutputFolder" -LogFile $LogFile
				Write-Log -Message "	UniqueSolutionName = $UniqueSolutionName" -LogFile $LogFile
				Write-Log -Message "	Managed = $Managed" -LogFile $LogFile
				
				$Result = Export-CrmSolution -CrmConn $Conn -FileName $FileName -OutputFolder $OutputFolder -UniqueSolutionName $UniqueSolutionName -Managed $Managed
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"import-crmaccessteamtemplates" { 
				$Params = Get-CommandParam $ScriptCommand.Param
				
				$FilePath = $Params["filepath"]
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	FilePath = $FilePath" -LogFile $LogFile
				
				$Result = Import-CrmAccessTeamTemplates -CrmConn $Conn -FilePath $FilePath
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"rename-crmbusinessunit" { 
				$Params = Get-CommandParam $ScriptCommand.Param 
				
				$CurrentName = $Params["currentname"]
				$NewName = $Params["newname"]
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	CurrentName = $CurrentName" -LogFile $LogFile
				Write-Log -Message "	NewName = $NewName" -LogFile $LogFile
				
				$Result = Rename-CrmBusinessUnit -CrmConn $Conn -CurrentName $CurrentName -NewName $NewName
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"rename-crmrootbusinessunit" { 
				$Params = Get-CommandParam $ScriptCommand.Param 
				
				$Name = $Params["name"]
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	Name = $Name" -LogFile $LogFile
				
				$Result = Rename-CrmRootBusinessUnit -CrmConn $Conn -Name $Name
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"remove-crmentityattributeoptionsetoption" { 
				$Params = Get-CommandParam $ScriptCommand.Param 
				
				$EntityLogicalName = $Params["entitylogicalname"]
				$AttributeLogicalName = $Params["attributelogicalname"]
				$OptionEnglishName = $Params["optionenglishname"]
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	EntityLogicalName = $EntityLogicalName" -LogFile $LogFile
				Write-Log -Message "	AttributeLogicalName = $AttributeLogicalName" -LogFile $LogFile
				Write-Log -Message "	OptionEnglishName = $OptionEnglishName" -LogFile $LogFile
				
				$Result = Remove-CrmEntityAttributeOptionSetOption -CrmConn $Conn -EntityLogicalName $EntityLogicalName  -AttributeLogicalName $AttributeLogicalName  -OptionEnglishName $OptionEnglishName
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"remove-crmentityattribute" { 
				$Params = Get-CommandParam $ScriptCommand.Param 
				
				$EntityLogicalName = $Params["entitylogicalname"]
				$AttributeLogicalName = $Params["attributelogicalname"]
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	EntityLogicalName = $EntityLogicalName" -LogFile $LogFile
				Write-Log -Message "	AttributeLogicalName = $AttributeLogicalName" -LogFile $LogFile
				
				$Result = Remove-CrmEntityAttribute -CrmConn $Conn -EntityLogicalName $EntityLogicalName  -AttributeLogicalName $AttributeLogicalName
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"remove-crmglobaloptionset" { 
				$Params = Get-CommandParam $ScriptCommand.Param 
				
				$OptionSetName = $Params["optionsetname"]
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	OptionSetName = $OptionSetName" -LogFile $LogFile
				
				$Result = Remove-CrmGlobalOptionSet -CrmConn $Conn -OptionSetName $OptionSetName
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"remove-crmprocess" { 
				$Params = Get-CommandParam $ScriptCommand.Param 
				
				$PrimaryEntityLogicalName = $Params["primaryentitylogicalname"]
				$ProcessName = $Params["processname"]
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	PrimaryEntityLogicalName = $PrimaryEntityLogicalName" -LogFile $LogFile
				Write-Log -Message "	ProcessName = $ProcessName" -LogFile $LogFile
				
				$Result = Remove-CrmProcess -CrmConn $Conn -PrimaryEntityLogicalName $PrimaryEntityLogicalName  -ProcessName $ProcessName
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"remove-crmrecord" { 
				$Params = Get-CommandParam $ScriptCommand.Param
				
				$EntityLogicalName = $Params["entitylogicalname"]
				$Id = $Params["id"]
				$Fields = Convert-StringToArray($Params["fields"])				
				$Values = Convert-StringToArray($Params["values"])
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	EntityLogicalName = $EntityLogicalName" -LogFile $LogFile
				
				[Guid]$NewGuid =  New-Object Guid
				If([Guid]::TryParse($Id, [ref]$NewGuid)) {
					Write-Log -Message "	Id  = $Id" -LogFile $LogFile
					$Result = Remove-CrmRecord -CrmConn $Conn -EntityLogicalName $EntityLogicalName -Id $NewGuid
					Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				}
				ElseIf(($Fields -gt 0) -and ($Values -gt 0)) {
					Write-Log -Message "	Fields   = $Fields" -LogFile $LogFile	
					Write-Log -Message "	Values   = $Values" -LogFile $LogFile	
					$Result = Remove-CrmRecord -CrmConn $Conn -EntityLogicalName $EntityLogicalName -Fields $Fields -Values $Values
					Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				}
				Else {
					 Throw "Id = $Id is not a valid GUID. Please use a valid GUID or use Fields and Values to find the record to be removed" 
				}

				break
			}
			"set-crmpluginsteprunasuser" { 
				$Params = Get-CommandParam $ScriptCommand.Param
				
				$StepName = $Params["stepname"]
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	StepName = $StepName" -LogFile $LogFile
				
				$Result = Set-CrmPluginStepRunAsUser -CrmConn $Conn -StepName $StepName
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"set-crmentityaccessteamtemplatestatus" { 
				$Params = Get-CommandParam $ScriptCommand.Param
				
				$EntityLogicalName = $Params["entitylogicalname"]
				$Enabled = $Params["enabled"] -ne "0"
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	EntityLogicalName = $EntityLogicalName" -LogFile $LogFile
				Write-Log -Message "	Enabled = $Enabled" -LogFile $LogFile
				
				$Result = Set-CrmEntityAccessTeamTemplateStatus -CrmConn $Conn -EntityLogicalName $EntityLogicalName -Enabled $Enabled
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
		
				break
			}
			"set-crmfieldsecurityprofileteam" { 
				$Params = Get-CommandParam $ScriptCommand.Param
				
				$FieldSecurityProfileName = $Params["fieldsecurityprofilename"]
				$Teams = Convert-StringToArray($Params["teams"])
				$Append = $Params["append"] -eq "1"
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	FieldSecurityProfileName = $FieldSecurityProfileName" -LogFile $LogFile
				Write-Log -Message "	Teams = $Teams" -LogFile $LogFile
				Write-Log -Message "    Append = $Append" -LogFile $LogFile
				
				$Result = Set-CrmFieldSecurityProfileTeam -CrmConn $Conn -FieldSecurityProfileName $FieldSecurityProfileName -Teams $Teams -Append $Append
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"set-crmrecord" { 
				$Params = Get-CommandParam $ScriptCommand.Param
				
				$EntityLogicalName = $Params["entitylogicalname"]
				$Id = $Params["id"]
				$Fields = Convert-StringToArray($Params["fields"])				
				$Values = Convert-StringToArray($Params["values"])
				$FilePath = $Params["filepath"]
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	EntityLogicalName = $EntityLogicalName" -LogFile $LogFile
				Write-Log -Message "	Id  = $Id" -LogFile $LogFile
				Write-Log -Message "	Fields   = $Fields" -LogFile $LogFile		
				
				[Guid]$NewGuid =  New-Object Guid
				If([Guid]::TryParse($Id, [ref]$NewGuid) -Or ($Id -eq $Null) ) {
					$Result = ""
				    If($Values -gt 0) {
				        Write-Log -Message "	Values   = $Values" -LogFile $LogFile	
						$Result = Set-CrmRecord -CrmConn $Conn -EntityLogicalName $EntityLogicalName -Id $NewGuid -Fields $Fields -Values $Values
					}
					else {	
				        Write-Log -Message "	FilePath = $FilePath" -LogFile $LogFile
						$Result = Set-CrmRecord -CrmConn $Conn -EntityLogicalName $EntityLogicalName -Id $NewGuid -Fields $Fields -FilePath $FilePath
					}
					
					Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				}
				Else {
					 Throw "Id = $Id is not a valid GUID. Please use a valid GUID" 
				}
				break
			}
			"set-crmserverurlinfile" { 	
                #Get all command parameters
				$Params = Get-CommandParam $ScriptCommand.Param

				$FilePath = $Params["filepath"]
				$ValueToReplace = $Params["valuetoreplace"]
                $IsLocal = $CrmServerUrl -Match "npl"

                $Url = ""

                #Set URL depending the lab and scms environments
                If($IsLocal) {
                    $Url = "$CrmServerUrl/$CrmOrgName"
                }
                Else {
                     $Url = $CrmServerUrl
                }

                #Display parameters
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	FilePath = $FilePath" -LogFile $LogFile
				Write-Log -Message "	ValueToReplace  = $ValueToReplace" -LogFile $LogFile
				Write-Log -Message "	CrmServerUrl  = $Url" -LogFile $LogFile

                if (Test-Path $FilePath) {                   
                    #Create backup file
                    $FilePathBak = "$FilePath.BAK"                    

                    if (-Not (Test-Path $FilePathBAK)) {
                        (Get-Content $FilePath) | Set-Content $FilePathBak
                    }
					
				    $Result = (Get-Content $FilePathBak).replace($ValueToReplace, $Url) 
                    $Result | Set-Content $FilePath
				    Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
			    }
                Else {
                    Throw "The file $FilePath Does Not Exist"
                }
				break
			}
			"set-crmteamsecurityroles" { 
				$Params = Get-CommandParam $ScriptCommand.Param
				
				$TeamName = $Params["teamname"]
				$SecurityRoles = Convert-StringToArray($Params["securityroles"])
				$Append = $Params["append"] -eq "1"
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	TeamName = $TeamName" -LogFile $LogFile
				Write-Log -Message "	SecurityRoles = $SecurityRoles" -LogFile $LogFile
				Write-Log -Message "    Append = $Append" -LogFile $LogFile
				
				$Result = Set-CrmTeamSecurityRoles -CrmConn $Conn -TeamName $TeamName -SecurityRoles $SecurityRoles -Append $Append
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"set-crmrecordactivationstatus" { 
				$Params = Get-CommandParam $ScriptCommand.Param
				
				$FetchXmlFilePath = $Params["fetchxmlfilepath"]		
				$StateCode = $Params["statecode"] -as [int]
				$StatusCode = $Params["statuscode"] -as [int]
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	FetchXmlFilePath = $FetchXmlFilePath" -LogFile $LogFile
				Write-Log -Message "	StateCode   = $StateCode" -LogFile $LogFile
				Write-Log -Message "	StatusCode   = $StatusCode" -LogFile $LogFile
				
				$Result = Set-CrmRecordActivationStatus -CrmConn $Conn -FetchXmlFilePath $FetchXmlFilePath -StateCode $StateCode -StatusCode $StatusCode
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"set-crmviewactivationstatus" { 
				$Params = Get-CommandParam $ScriptCommand.Param
				
				$EntityLogicalName = $Params["entitylogicalname"]				
				$Fields = Convert-StringToArray($Params["fields"])				
				$Values = Convert-StringToArray($Params["values"])
				$Activate = $Params["activate"] -ne "0"
				
				Write-Log -Message "$CommandType" -LogFile $LogFile
				Write-Log -Message "	EntityLogicalName = $EntityLogicalName" -LogFile $LogFile
				Write-Log -Message "	Fields   = $Fields" -LogFile $LogFile
				Write-Log -Message "	Values   = $Values" -LogFile $LogFile
				Write-Log -Message "	Activate = $Activate" -LogFile $LogFile
				
				$Result = Set-CrmViewActivationStatus -CrmConn $Conn -EntityLogicalName $EntityLogicalName -Fields $Fields -Values $Values -Activate $Activate
				Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				break
			}
			"sync-crmdatabyid" { 	
				If($ConnSource -and $Conn) {
					$Params = Get-CommandParam $ScriptCommand.Param
				
					$EntitySource = $Params["entitysource"]
					$EntityTarget = $Params["entitytarget"]
					$ColumnsToCompare = Convert-StringToArray($Params["columnstocompare"])
					$UpdateMismatch = $Params["updatemismatch"] -ne "0"
					$SourceFetchXmlFile = $Params["sourcefetchxmlfile"]
					
					Write-Log -Message "$CommandType" -LogFile $LogFile
					Write-Log -Message "	EntitySource = $EntitySource" -LogFile $LogFile
					Write-Log -Message "	EntityTarget  = $EntityTarget" -LogFile $LogFile
					Write-Log -Message "	ColumnsToCompare = $ColumnsToCompare" -LogFile $LogFile
					Write-Log -Message "	UpdateMismatch  = $UpdateMismatch" -LogFile $LogFile
					Write-Log -Message "	SourceFetchXmlFile = $SourceFetchXmlFile" -LogFile $LogFile
					
					$Result = Sync-CrmDataById -CrmConnSource $ConnSource -CrmConnTarget $Conn  -EntitySource $EntitySource -EntityTarget $EntityTarget -ColumnsToCompare $ColumnsToCompare -UpdateMismatch $UpdateMismatch
					Write-Log -Message "$Result" -LogFile $LogFile -Color "green" -AddDate:$False
				}
				Else {
					 Throw "Please check your CRM Source & Target environmenents connection parameters" 
				}
				break
			}
			default 
			{				
				Throw "The command $CommandType does not exit"
			}			
		}

		Write-Log -Message " " -LogFile $LogFile -AddDate:$False
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
	
If($ErrorOccured) {
	Write-Log -Message "THE SCRIPT $ScriptBasename FAILED" -LogFile $LogFile -Color "red"
}
else {
	Write-Log -Message "THE SCRIPT $ScriptBasename COMPLETED SUCCESSFULLY" -LogFile $LogFile -Color "yellow"
}
