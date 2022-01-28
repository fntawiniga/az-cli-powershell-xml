Using Module ".\AzReturn.psm1"

Class AzReturnParam {
    [String] $Name
    [String] $Value
    [AzReturn] $Return

    AzReturnParam([String] $Name, [String] $Value, [AzReturn] $Return) {
        $This.Name = $Name
        $This.Value = $Value
        $This.Return = $Return
    }
}
