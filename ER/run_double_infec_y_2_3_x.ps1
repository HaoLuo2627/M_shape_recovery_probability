$max_jobs = 8
$jobs = @()

for ($i = 40; $i -le 66; $i++) {
    if ($i -gt 0)
    {
        $theta = $i * 0.01;
    }
    else
    {
        $theta = 0.001;
    }
    $beta = -1 + 2 / (3 * $theta);
    Write-Host "Running with theta = $theta, beta = $beta"

    $proc = Start-Process .\double_infec.exe `
        -ArgumentList "0 10 $beta $theta 1 1" `
        -RedirectStandardOutput "beta_${beta}_theta_${theta}_out.log" `
        -RedirectStandardError "beta_${beta}_theta_${theta}_err.log" `
        -PassThru
    $jobs += $proc

    # 达到并发上限时，等待任意一个进程结束再继续
    if ($jobs.Count -ge $max_jobs) {
        do {
            Start-Sleep -Milliseconds 200
            $jobs = @($jobs | Where-Object { -not $_.HasExited })
        } while ($jobs.Count -ge $max_jobs)
    }
}

# 等待剩余所有进程结束
if ($jobs.Count -gt 0) {
    Wait-Process -InputObject $jobs
}
Write-Host "All processes completed."
