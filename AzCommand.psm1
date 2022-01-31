Using Module ".\AzParam.psm1"

Class AzCommand {
    [String] $Type
    [String] $Return
    [AzParam[]] $Params

    AzCommand([String] $Type, [String] $Return, [AzParam[]] $Params) {
        $ObjectType = $This.GetType()

        If($ObjectType -eq [AzCommand]) {
            Throw("Class $ObjectType must be inherited")
        }

        $This.Type = $Type
        $This.Return = $Return
        $This.Params = $Params
    }

    [String] Execute() {
        Throw("Must Override Method")
    }
}