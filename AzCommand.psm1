Using Module ".\AzParam.psm1"

Class AzCommand {
    [String] $Type
    [String] $Return
    [AzParam[]] $Params

    AzCommand($Type, $Return, $Params) {
        $This.Type = $Type
        $This.Return = $Return
        $This.Params = $Params
    }
}