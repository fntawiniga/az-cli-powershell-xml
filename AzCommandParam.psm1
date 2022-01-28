Using Module ".\AzReturn.psm1"

Class AzCommandParam {
    [String] $Name
    [String] $Value
    [AzReturn] $Return

    AzCommandParam([String] $Name, [String] $Value, [AzReturn] $Return) {
        $This.Name = $Name
        $This.Value = $Value
        $This.Return = $Return
    }
}
