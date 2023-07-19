# Add-Type directive to load the .NET assembly for System.Net.NetworkInformation
Add-Type -AssemblyName System.Net

# Prompt for the IP address to ping
$IPAddress = Read-Host "Enter the IP address you want to ping"

# Function to run ping command with -n 200 and display latency and TTL
function RunPing {
    param($ipAddress)

    Write-Host "Pinging $IPAddress 200 times..."

    $pingSender = New-Object System.Net.NetworkInformation.Ping
    $pingOptions = New-Object System.Net.NetworkInformation.PingOptions
    $latencies = @()

    for ($i = 0; $i -lt 200; $i++) {
        $reply = $pingSender.Send($IPAddress, 1000, [byte[]]::new(32), $pingOptions)

        if ($reply.Status -eq 'Success') {
            $latencies += $reply.RoundtripTime
            Write-Host ("Reply from {0}: bytes=32 time={1}ms TTL={2}" -f $IPAddress, $reply.RoundtripTime, $reply.Options.Ttl)
        }
        else {
            Write-Host "Request timed out."
        }
    }

    # Calculate and display statistics
    $received = $latencies.Count
    $lost = 200 - $received
    $lossPercentage = ($lost / 200) * 100

    $output = "Ping statistics for {0}:`n" -f $IPAddress
    $output += "    Packets: Sent = 200, Received = {0}, Lost = {1} (Loss Percentage = {2:F2}%)" -f $received, $lost, $lossPercentage
    $output += "`n"

    if ($received -gt 0) {
        $avgLatency = $latencies | Measure-Object -Average | Select-Object -ExpandProperty Average
        $minLatency = $latencies | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
        $maxLatency = $latencies | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum

        $output += "Approximate round trip times in milliseconds:`n"
        $output += "    Minimum = {0} ms,`n" -f $minLatency
        $output += "    Maximum = {0} ms,`n" -f $maxLatency
        $output += "    Average = {0:F2} ms`n" -f $avgLatency
    }

    # Output the results to the console
    Write-Host $output
}

# Main script execution
try {
    RunPing $IPAddress
}
catch {
    Write-Host "Error occurred: $_"
}

# Add this line to wait for user input before closing the console
Read-Host "Press Enter to exit."