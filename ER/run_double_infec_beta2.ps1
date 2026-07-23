$theta_array = @(0, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5)
$beta = 2

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