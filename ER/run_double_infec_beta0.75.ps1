$theta_array = @(0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.85, 0.9, 0.95, 1)
$beta = 0.75

$processes = @()

foreach ($theta in $theta_array) {
    Write-Host "Running with theta = $theta"
    $process = Start-Process .\double_infec.exe `
        -ArgumentList "0 10 $beta $theta $beta $theta" `
        -RedirectStandardOutput "beta_${beta}_theta_${theta}_out.log" `
        -RedirectStandardError "beta_${beta}_theta_${theta}_err.log" `
        #-NoWindow `
        #-PassThru
    $processes += $process
}

# 等待所有后台进程完成
$processes | ForEach-Object { $_.WaitForExit() }
Write-Host "All processes completed."