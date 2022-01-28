Using Module ".\AzParam.psm1"

Class AzCommand {
    [String] $Type
    [AzParam[]] $Params

    AzCommand($Type, $Params) {
        $This.Type = $Type
        $This.Params = $Params
    }
}