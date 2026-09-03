$a_parameterValues = @('0.01', '0.2', '0.5', '0.8', '0.99')
$c_parameterValues = @('0.01', '0.2', '0.5', '0.8', '1')
$v = 2
$executable = Join-Path $PSScriptRoot 'double_infec.exe'

if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
    throw "Executable not found: $executable"
}

$originalLocation = Get-Location
$totalRuns = $a_parameterValues.Count * $c_parameterValues.Count
$runNumber = 0

try {
    Set-Location -LiteralPath $PSScriptRoot

    foreach ($A_a in $a_parameterValues) {
        $batchProcesses = @()

        Write-Host "Starting $($c_parameterValues.Count) processes in parallel for a=$A_a, v=$v..."

        try {
            foreach ($A_c in $c_parameterValues) {
                $B_a = $A_a
                $B_c = $A_c
                $runNumber++

                Write-Host "[$runNumber/$totalRuns] .\double_infec.exe 0 10 $A_a $A_c $B_a $B_c $v"
                $process = Start-Process `
                    -FilePath $executable `
                    -ArgumentList @('0', '10', $A_a, $A_c, $B_a, $B_c, $v) `
                    -WorkingDirectory $PSScriptRoot `
                    -NoNewWindow `
                    -PassThru

                $batchProcesses += [pscustomobject]@{
                    Process = $process
                    A_a     = $A_a
                    A_c     = $A_c
                    B_a     = $B_a
                    B_c     = $B_c
                    v       = $v
                }
            }

            $failures = @()
            foreach ($run in $batchProcesses) {
                $run.Process.WaitForExit()

                if ($run.Process.ExitCode -ne 0) {
                    $failures += $run
                }
            }

            if ($failures.Count -gt 0) {
                $failureDetails = $failures | ForEach-Object {
                    "exit code $($_.Process.ExitCode) (A_a=$($_.A_a), A_c=$($_.A_c), B_a=$($_.B_a), B_c=$($_.B_c), v=$($_.v))"
                }
                throw "double_infec.exe failed:`n$($failureDetails -join "`n")"
            }

            Write-Host "Completed all c values for a=$A_a, v=$v."
        }
        finally {
            foreach ($run in $batchProcesses) {
                if (-not $run.Process.HasExited) {
                    $run.Process.WaitForExit()
                }
                $run.Process.Dispose()
            }
        }
    }

    Write-Host "Completed all $totalRuns SF v = $v parameter combinations."
}
finally {
    Set-Location -LiteralPath $originalLocation
}
