Using Module ".\AzReturnParam.psm1"

Class AzReturn {
    [String] $Type
    [AzReturnParam[]] $Params

    AzReturn($Type, $Params) {
        $This.Type = $Type
        $This.Params = $Params
    }
}