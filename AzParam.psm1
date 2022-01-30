Class AzParam {
    [String] $Name
    [String] $Value

    AzParam($Name, $Value) {
        $This.Name = $Name
        $This.Value = $Value
    }
}