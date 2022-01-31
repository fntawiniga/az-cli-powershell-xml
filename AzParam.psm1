Class AzParam {
    [String] $Name
    [String] $Value

    AzParam([String] $Name, [String] $Value) {
        $This.Name = $Name
        $This.Value = $Value
    }
}