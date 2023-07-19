function Ping-IP {
    param (
        [string]$ipAddress,
        [int]$count = 1
    )

    $pingCommand = "ping"
    $pingArgs = "-n", $count, $ipAddress

    $pingResult = & $pingCommand $pingArgs 2>&1

    # Extract the relevant statistics from the output
    $statistics = $pingResult | Select-String "Packets: Sent = (\d+), Received = (\d+), Lost = (\d+).+(\d+)% loss" -AllMatches

    if ($statistics.Matches.Count -eq 1) {
        $sent = [int]$statistics.Matches[0].Groups[1].Value
        $received = [int]$statistics.Matches[0].Groups[2].Value
        $lost = [int]$statistics.Matches[0].Groups[3].Value
        $lossPercentage = [int]$statistics.Matches[0].Groups[4].Value

        $pingSummary = [PSCustomObject]@{
            Sent = $sent
            Received = $received
            Lost = $lost
            LossPercentage = $lossPercentage
            AdditionalInfo = $pingResult
        }

        return $pingSummary
    } else {
        return "Error: Ping statistics not found."
    }
}

function Clear-Screen {
    Clear-Host
}

function Main {
    Clear-Screen

    Write-Output "Ping Tool - Enter IP addresses to send 200 ICMP requests"

    $usableIP = Read-Host "Enter the 'usable' IP address"
    $gatewayIP = Read-Host "Enter the 'gateway' IP address"

    Clear-Screen

    Write-Output "Sending 200 ICMP requests to 'usable' IP address ($usableIP) and 'gateway' IP address ($gatewayIP)..."

    $usableResults = @()
    $gatewayResults = @()

    for ($i = 1; $i -le 200; $i++) {
        $usableResults += Ping-IP -ipAddress $usableIP
        $gatewayResults += Ping-IP -ipAddress $gatewayIP
    }

    Clear-Screen

    Write-Output "Pinging completed!"

    Write-Output "Results for 'usable' IP address ($usableIP):"
    $usableTotal = Get-PingSummary -PingResults $usableResults
    Write-Output "Sent = $($usableTotal.Sent), Received = $($usableTotal.Received), Lost = $($usableTotal.Lost), LossPercentage = $($usableTotal.LossPercentage)%`n"

    Write-Output "Results for 'gateway' IP address ($gatewayIP):"
    $gatewayTotal = Get-PingSummary -PingResults $gatewayResults
    Write-Output "Sent = $($gatewayTotal.Sent), Received = $($gatewayTotal.Received), Lost = $($gatewayTotal.Lost), LossPercentage = $($gatewayTotal.LossPercentage)%`n"
}

function Get-PingSummary {
    param (
        [array]$PingResults
    )

    $totalSent = 0
    $totalReceived = 0
    $totalLost = 0

    foreach ($result in $PingResults) {
        $totalSent += $result.Sent
        $totalReceived += $result.Received
        $totalLost += $result.Lost
    }

    $totalLossPercentage = 0
    if ($totalSent -gt 0) {
        $totalLossPercentage = [math]::Round(($totalLost / $totalSent) * 100, 2)
    }

    $summary = [PSCustomObject]@{
        Sent = $totalSent
        Received = $totalReceived
        Lost = $totalLost
        LossPercentage = $totalLossPercentage
    }

    return $summary
}

Main