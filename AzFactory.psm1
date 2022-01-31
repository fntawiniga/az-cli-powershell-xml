Using Module ".\AzCommand.psm1"
Using Module ".\AzParam.psm1"
Using Module ".\AzCommandGlobalVariables.psm1"

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