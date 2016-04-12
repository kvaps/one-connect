; Getting params
$param=''
For $i = 1 To $CmdLine[0]
   $param &= " " & $CmdLine[$i]
Next

; Start script
Run("bash.exe vm-connect.sh" & $param)
Local $hWnd = WinWait("[CLASS:ConsoleWindowClass]", "", 10)

; Hide console window
WinSetState($hWnd, "", @SW_HIDE)
