# Function to run ping command with -n 200 and return latency and TTL info
function RunPing {
    param($ipAddress)
    
    $pingSender = New-Object System.Net.NetworkInformation.Ping
    $pingOptions = New-Object System.Net.NetworkInformation.PingOptions
    $latencies = @()

    for ($i = 0; $i -lt 200; $i++) {
        $reply = $pingSender.Send($IPAddress, 1000, [byte[]]::new(32), $pingOptions)

        if ($reply.Status -eq 'Success') {
            $latencies += $reply.RoundtripTime
        }
    }

    # Return the latencies
    $latencies
}

# Prompt for the "usable" IP address to ping
$UsableIPAddress = Read-Host "Enter the usable IP address you want to ping"

# Prompt for the "gateway" IP address to ping
$GatewayIPAddress = Read-Host "Enter the gateway IP address you want to ping"

# Main script execution
try {
    # Run the ping commands in the background jobs
    $usableJob = Start-Job -ScriptBlock ${function:RunPing} -ArgumentList $UsableIPAddress
    $gatewayJob = Start-Job -ScriptBlock ${function:RunPing} -ArgumentList $GatewayIPAddress

    # Wait for the jobs to finish
    Wait-Job $usableJob, $gatewayJob | Out-Null

    # Get the results from the jobs
    $usableResult = Receive-Job $usableJob
    $gatewayResult = Receive-Job $gatewayJob

    # Display the output of each ping test separately
    Write-Host ("Ping results for {0}:" -f $UsableIPAddress)
    if ($usableResult.Count -gt 0) {
        foreach ($latency in $usableResult) {
            Write-Host ("Reply from {0}: bytes=32 time={1}ms TTL=128" -f $UsableIPAddress, $latency)
        }
    } else {
        Write-Host "Request timed out."
    }

    Write-Host

    Write-Host ("Ping results for {0}:" -f $GatewayIPAddress)
    if ($gatewayResult.Count -gt 0) {
        foreach ($latency in $gatewayResult) {
            Write-Host ("Reply from {0}: bytes=32 time={1}ms TTL=128" -f $GatewayIPAddress, $latency)
        }
    } else {
        Write-Host "Request timed out."
    }

    Write-Host

    # Display the final statistics and average latency for both ping tests
    if ($usableResult.Count -gt 0 -and $gatewayResult.Count -gt 0) {
        $usableAvgLatency = $usableResult | Measure-Object -Average | Select-Object -ExpandProperty Average
        $gatewayAvgLatency = $gatewayResult | Measure-Object -Average | Select-Object -ExpandProperty Average

        Write-Host ("Ping statistics for {0} and {1}:" -f $UsableIPAddress, $GatewayIPAddress)
        Write-Host ("    Packets: Sent = 200, Received = {0}/{3}, Lost = {1}/{3} (Loss Percentage = {2:F2}%)" -f $usableResult.Count, (200 - $usableResult.Count), ((200 - $usableResult.Count) / 200) * 100, $usableResult.Count)
        Write-Host "Approximate round trip times in milliseconds:"
        Write-Host ("    {0} - Average = {1:F2} ms" -f $UsableIPAddress, $usableAvgLatency)
        Write-Host ("    {0} - Average = {1:F2} ms" -f $GatewayIPAddress, $gatewayAvgLatency)
    }
}
catch {
    Write-Host "Error occurred: $_"
}
finally {
    # Cleanup: Remove the background jobs
    if ($usableJob) { Remove-Job $usableJob -Force }
    if ($gatewayJob) { Remove-Job $gatewayJob -Force }
}

# Add this line to wait for user input before closing the console
Read-Host "Press Enter to exit."