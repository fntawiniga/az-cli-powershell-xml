Using Module ".\AzCommand.psm1"
Using Module ".\AzParam.psm1"

Class AzCommandGlobalVariables : AzCommand {

    AzCommandGlobalVariables([String] $Type, [String] $Return, [AzParam[]] $Params) : base ($Type, $Return, $Params) {
       <#  Foreach ($Param in $This.Params){
            Write-Host "$($Param.Name) : $($Param.Value)"
        } #>
    }

    [String] Execute() {
        Throw("Must Override Method")
    }
}