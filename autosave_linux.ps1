function push(){
    if($isNewsave){
        foreach ($item in 1..6){
            Start-Sleep -s 5
            $newsave = (Get-ItemProperty $path).LastWriteTime
            write-host $oldsave $newsave
            if($oldsave -ne $newsave){
                break
            }
        }
    }
    else{
        $newsave = (Get-ItemProperty $path).LastWriteTime
    }
    
    $saveName = Join-Path $backup_Location $path
    Copy-Item $path $saveName -Force
    Set-Location $backup_Location
    git pull origin master
    $date = $newsave.ToString("yyyy/MM/dd HH:mm:ss")
    git commit -m "$date" .
    git push origin master
    Set-Location $Location
    write-host "Finish push"
}

    function saveCopy(){
        if($isNewsave){
            foreach ($item in 1..6){
                Start-Sleep -s 5
                $newsave = (Get-ItemProperty $path).LastWriteTime
                write-host $oldsave $newsave
                if($oldsave -ne $newsave){
                    break
                }
            }
        }
        else{
            $newsave = (Get-ItemProperty $path).LastWriteTime
        }
    
        $saveTime = $newsave.ToString("MMddHHmm")
        $saveName = Join-Path $backup_Location "$path_basename$saveTime.sve"
        Copy-Item $path $saveName
        write-host "Finish copy"
    }

# autosave_pakname.ps1 の形でスクリプト名を書き、そこからpaknameを切り出す
$script_name = Split-Path -Leaf $PSCommandPath
$pakname = $script_name.remove(0,9)
$pakname = $pakname.remove($pakname.length -4,4) # 拡張子切り落とし

$pakname_server = $pakname + "_server"


# 初期設定 (各自環境に併せて入力)
$mode = "saveCopy"  # セーブデータをコピーして保管する際にはpushをsaveCopyに、gitを使用したバックアップを行う際はsaveCopyをpushに書き換えること
$backup_Location = "./save"      # "../simutrans_save" のようにsaveデータをコピーして保管するフォルダパスを書く
$restart_Object = "./$pakname_server" # KU-TANS標準の起動スクリプトを使用しない際は、再起動時に実行するものに書き換えること
$span = 30  # オートセーブ間隔（分）　デフォルトは約30分
# 各自の入力範囲　ここまで

$Location = Get-Location

$ver = Import-Csv version
$ver_server = Import-Csv version_server

foreach ($a in $ver) {
    if ($a.pakName -eq $pakname){
        $ip = $a.ip
        break
    }
}
foreach ($b in $ver_server) {
    if ($b.pakName -eq $pakname){
        $pass = $b.pass
        break
    }
}

$port_colon = $ip.IndexOf(':')

if ($port_colon -eq -1){
    $port = "13353"
}
else {
    $port = $ip.remove(0,$port_colon+1)
}

$path = "server$port-network.sve"
$path_basename = $path.remove($path.length -4,4)
$spanMeasure = $span - 2
$spanSeconds = $span * 60
$sleepSeconds = $spanSeconds - 118
$isClients = $false
./nettool -s $ip -p $pass -q say "Start"

while(1){
    # クライアント数の把握
    $clients = @(./nettool -s $ip -p $pass -q clients)
    $e_code = $LastExitCode
    write-host $clients
    
    if ($e_code -eq 0){
        if ($clients.length -ge 2){
            $isClients = $true
            $oldsave = (Get-ItemProperty $path).LastWriteTime
            if($oldsave -le [datetime]::Now.AddMinutes( -$spanMeasure )){
                ./nettool -s $ip -p $pass -q say "Autosave after 120 seconds"
                Start-Sleep -s 90
                $oldsave = (Get-ItemProperty $path).LastWriteTime
                if($oldsave -le [datetime]::Now.AddMinutes( -$spanMeasure )){
                    ./nettool -s $ip -p $pass -q say "Autosave soon"
                    Start-Sleep -s 30
                    $oldsave = (Get-ItemProperty $path).LastWriteTime
                    if($oldsave -le [datetime]::Now.AddMinutes( -$spanMeasure )){
                        ./nettool -s $ip -p $pass -q force-sync
                        $isNewsave = $true
                    }
                    else{
                        ./nettool -s $ip -p $pass -q say "Autosave has been cancelled"
                        $isNewsave = $false
                    }
                }
                else{
                    ./nettool -s $ip -p $pass -q say "Autosave has been cancelled"
                    $isNewsave = $false
                }
                & $mode
    
                $time = [datetime]::Now.Addseconds($spanSeconds).ToString("HH:mm")
                ./nettool -s $ip -p $pass -q say "Next autosave will be in $spanSeconds seconds ( $time )"
                Start-Sleep -s $sleepSeconds
            }
            else{
                $isNewsave = $false
                & $mode
    
                $wait = $spanSeconds - [int]([datetime]::Now - (Get-ItemProperty $path).LastWriteTime).totalseconds
                $time = [datetime]::Now.Addseconds($wait).ToString("HH:mm")
                ./nettool -s $ip -p $pass -q say "Autosave in $wait seconds ( $time )"
                $wait = $wait - 118
                Start-Sleep -s $wait
            }
        }
        else{
            # 誰もいなくなったときに自動で再起動する
            if($isClients){
                $oldsave = (Get-ItemProperty $path).LastWriteTime
                ./nettool -s $ip -p $pass -q force-sync
                $isNewsave = $true
                & $mode
                ./nettool -s $ip -p $pass -q shutdown
                write-host "restart"
                $isClients = $false
                Start-Sleep -s 5
                Invoke-Expression $restart_Object
            }
            Start-Sleep -s $sleepSeconds
        }
    }
    elseif($e_code -eq 1){
        # サーバーに到達できないときは、ゲームが落ちていると判定し、再起動処理をする
        write-host "Not started"
        Invoke-Expression $restart_Object
        Start-Sleep -s $sleepSeconds
    }
    else{
        # なにかその他エラーが発生したときは5分後に再度実行
        write-host "miss"
        Start-Sleep -s 300
    }
}