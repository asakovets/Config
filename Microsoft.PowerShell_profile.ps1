function env { Get-ChildItem Env: }
function q { exit }

function _dev {
    & "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
    pwsh
}

Set-Alias -Name which -Value get-command
Set-Alias -Name o     -Value Start-Process

# $env:PATH = "$env:PATH:~/.local/bin/"
$Env:PATH += ";$HOME/.local/bin/"

mise activate pwsh | Out-String | Invoke-Expression


function prompt {
    $p = $executionContext.SessionState.Path.CurrentLocation
    $osc7 = ""
    if ($p.Provider.Name -eq "FileSystem") {
        $ansi_escape = [char]27
        $provider_path = $p.ProviderPath -Replace "\\", "/"
        $osc7 = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}${ansi_escape}\"
    }
    "${osc7}PS $p$('>' * ($nestedPromptLevel + 1)) ";
}

if (Get-Command coreutils.exe -ErrorAction SilentlyContinue) {
    remove-alias ls,rm,cp,mv,echo

    function ls {
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            $args
        )
        $lsPath = (Get-Command ls.exe -ErrorAction SilentlyContinue).Source
        if (-not $lsPath) {
            throw "Could not find external ls.exe"
        }
        & $lsPath --color=auto @args
    }
}
