# autosave_pakname.ps1 の形でスクリプト名を書き、そこからpaknameを切り出す
$script_name = Split-Path -Leaf $PSCommandPath
$pakname = $script_name.remove(0,9)
$pakname = $pakname.remove($pakname.length -4,4) # 拡張子切り落とし

$pakname_server = $pakname + "_server"


# 初期設定 (各自環境に併せて入力)
$mode = "push"  # セーブデータをコピーして保管する際にはpushをsaveCopyに、gitを使用したバックアップを行う際はsaveCopyをpushに書き換えること
$backup_Location = ""      # "../simutrans_save" のようにsaveデータをコピーして保管するフォルダパスを書く
$restart_Object = "./$pakname_server" # KU-TANS標準の起動スクリプトを使用しない際は、再起動時に実行するものに書き換えること
$span = 30  # オートセーブ間隔（分）　デフォルトは約30分
$check_State = 5  # 最新セーブおよびプレイヤーの有無の確認タイミング（分）　デフォルトでは約5分
# 各自の入力範囲　ここまで

# sleep
function select_SleepTime(){
    if($wait -le $check_StateSeconds){
        Start-Sleep -s $wait
    }
    else{
        Start-Sleep -s $check_StateSeconds
    }
}

# セーブデータが更新されるのを待つ
function waitSave(){
    if($script:isNewsave){
        foreach ($item in 1..6){
            Start-Sleep -s 5
            $newsave = (Get-ItemProperty $path).LastWriteTime
            write-host $oldsave $newsave
            if($oldsave -ne $newsave){
                return $newsave
            }
        }
    }
    else{
        return (Get-ItemProperty $path).LastWriteTime
    }
}

# セーブデータをGitにpushする
function push(){
    $newsave = waitSave

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

# セーブデータをフォルダにバックアップする
function saveCopy(){
    $newsave = waitSave

    $saveTime = $newsave.ToString("MMddHHmm")
    $saveName = Join-Path $backup_Location "$path_basename$saveTime.sve"
    Copy-Item $path $saveName
    write-host "Finish copy"
}

# nettoolからの戻り値の判定
function nettool_error(){
    if ($LastExitCode -eq 0){
        return $false
    }
    elseif($LastExitCode -eq 1){
        # サーバーに到達できないときは、ゲームが落ちていると判定し、再起動処理をする
        write-host "Not started"
        Invoke-Expression $restart_Object
        Start-Sleep -s $check_StateSeconds
        return $true
    }
    else{
        # なにかその他エラーが発生したときは1分後に再度実行
        write-host "miss"
        Start-Sleep -s 60
        return $true
    }
}

# ゲームを再起動するか判定
function checkRestart(){
    if($script:isClients){
        # 直前まで誰かがいた場合は自動で再起動する
        write-host $clients
        ./nettool -s $ip -p $pass -q force-sync
        $script:isNewsave = $true
        & $mode
        $script:beforesave = (Get-ItemProperty $path).LastWriteTime
        ./nettool -s $ip -p $pass -q shutdown
        write-host "restart"
        $script:isClients = $false
        Start-Sleep -s 5
        Invoke-Expression $restart_Object
        Start-Sleep -s $check_StateSeconds
    }
    else{
        # 条件を満たさなければスリープ
        write-host $clients
        Start-Sleep -s $check_StateSeconds
    }
}

# クライアント数の把握
function getClient() {
    $clients = @(./nettool -s $ip -p $pass -q clients)
    if (nettool_error){
        return "error"
    }
    
    if ($clients.length -lt 2){
        checkRestart
        return "error"
    }

    return $clients
}

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

if ($check_State -gt $span - 2){
    $check_State = $span - 2
}

$path = "server$port-network.sve"
$script:beforesave = (Get-ItemProperty $path).LastWriteTime
$path_basename = $path.remove($path.length -4,4)
$spanMeasure = $span - 2
$spanSeconds = $span * 60
$check_StateSeconds = $check_State * 60
$script:isClients = $false
./nettool -s $ip -p $pass -q say "Start"

while(1){
    # クライアント数の把握
    $clients = getClient
    if ($clients -eq "error"){
        continue
    }
    write-host $clients

    $script:isClients = $true
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
                $script:isNewsave = $true
            }
            else{
                ./nettool -s $ip -p $pass -q say "Autosave has been cancelled"
                $script:isNewsave = $false
            }
        }
        else{
            ./nettool -s $ip -p $pass -q say "Autosave has been cancelled"
            $script:isNewsave = $false
        }
        & $mode
        $script:beforesave = (Get-ItemProperty $path).LastWriteTime
        write-host $script:beforesave 
        
        $wait = $spanSeconds - [int]([datetime]::Now - $script:beforesave).totalseconds
        $time = [datetime]::Now.Addseconds($wait).ToString("HH:mm")
        ./nettool -s $ip -p $pass -q say "Next autosave will be in $spanSeconds seconds ( $time )"
        Start-Sleep -s $check_StateSeconds
    }
    elseif($oldsave -ne $script:beforesave){
        # Write-Host $oldsave $script:beforesave
        $script:isNewsave = $false
        & $mode
        $script:beforesave = (Get-ItemProperty $path).LastWriteTime
        write-host $script:beforesave 

        $wait = $spanSeconds - [int]([datetime]::Now - $script:beforesave).totalseconds
        $time = [datetime]::Now.Addseconds($wait).ToString("HH:mm")
        ./nettool -s $ip -p $pass -q say "Autosave in $wait seconds ( $time )"
        $wait = $wait - 119
        select_SleepTime
    }
    else{
        $wait = $spanSeconds - [int]([datetime]::Now - $script:beforesave).totalseconds
        $wait = $wait - 119
        select_SleepTime
    }
}