Add-Type -AssemblyName System.Net
Add-Type -AssemblyName System.Windows.Forms

function RunPing {
    param($ipAddress)

    $pingResults = ""
    $pingSender = New-Object System.Net.NetworkInformation.Ping
    $pingOptions = New-Object System.Net.NetworkInformation.PingOptions
    $latencies = @()
    $timeoutMessageAdded = $false

    for ($i = 0; $i -lt 200; $i++) {
        $reply = $pingSender.Send($IPAddress, 1000, [byte[]]::new(32), $pingOptions)

        if ($reply.Status -eq 'Success') {
            $latencies += $reply.RoundtripTime
        } else {
            if (-not $timeoutMessageAdded) {
                $pingResults += "Request timed out.`n"
                $timeoutMessageAdded = $true
            }
        }
    }

    # Calculate and display statistics
    $received = $latencies.Count
    $lost = 200 - $received
    $lossPercentage = ($lost / 200) * 100

    $pingResults += "`nPing statistics for $($ipAddress):`n"
    $pingResults += "    Packets: Sent = 200, Received = $received, Lost = $lost (Loss Percentage = {0:F2}%)`n" -f $lossPercentage

    if ($received -gt 0) {
        $avgLatency = $latencies | Measure-Object -Average | Select-Object -ExpandProperty Average
        $minLatency = $latencies | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
        $maxLatency = $latencies | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum

        $pingResults += "`nApproximate round trip times in milliseconds:`n"
        $pingResults += "    Minimum = {0} ms`n" -f $minLatency
        $pingResults += "    Maximum = {0} ms`n" -f $maxLatency
        $pingResults += "    Average = {0:F2} ms`n" -f $avgLatency
    }

    # Return the results
    return $pingResults
}

function RunPingForBothIPs {
    $usableIP = $textBoxUsableIP.Text
    $gatewayIP = $textBoxGatewayIP.Text

    # Clear the output text box and set the message
    $outputTextBox.Text = "Pinging IPs. Please Wait..."
    $form.Refresh()  # Force UI update

    # Validate the input to ensure at least one valid IP address is provided
    $validIPProvided = $false
    if ([System.Net.IPAddress]::TryParse($usableIP, [ref]$null)) {
        $validIPProvided = $true
        # Run the script for the usable IP
        $outputTextBox.Text += "`nResults for Usable IP ($usableIP):`n"
        $outputTextBox.Text += RunPing $usableIP
    }

    if ([System.Net.IPAddress]::TryParse($gatewayIP, [ref]$null)) {
        $validIPProvided = $true
        # Add a separator
        if ($outputTextBox.Text.Length -gt 0) {
            $outputTextBox.Text += "`n=================`n"
        }
        # Run the script for the gateway IP
        $outputTextBox.Text += "Results for Gateway IP ($gatewayIP):`n"
        $outputTextBox.Text += RunPing $gatewayIP
    }

    if (-not $validIPProvided) {
        # No valid IP address provided
        $outputTextBox.Text = "Please enter at least one valid IP address."
    }
}

function ResetForm {
    # Clear the text boxes and output
    $textBoxUsableIP.Text = ""
    $textBoxGatewayIP.Text = ""
    $outputTextBox.Text = ""
}

# Create the form
$form = New-Object Windows.Forms.Form
$form.Text = "Ping Tool"
$form.Size = New-Object Drawing.Size(400, 400)
$form.StartPosition = "CenterScreen"

# Create labels
$labelUsableIP = New-Object Windows.Forms.Label
$labelUsableIP.Text = "Enter the Usable IP address:"
$labelUsableIP.Location = New-Object Drawing.Point(10, 20)
$labelUsableIP.AutoSize = $true

$labelGatewayIP = New-Object Windows.Forms.Label
$labelGatewayIP.Text = "Enter the Gateway IP address:"
$labelGatewayIP.Location = New-Object Drawing.Point(10, 60)
$labelGatewayIP.AutoSize = $true

# Create text boxes
$textBoxUsableIP = New-Object Windows.Forms.TextBox
$textBoxUsableIP.Location = New-Object Drawing.Point(200, 20)
$textBoxUsableIP.Size = New-Object Drawing.Size(150, 20)

$textBoxGatewayIP = New-Object Windows.Forms.TextBox
$textBoxGatewayIP.Location = New-Object Drawing.Point(200, 60)
$textBoxGatewayIP.Size = New-Object Drawing.Size(150, 20)

# Create a button to run the ping for both IPs
$buttonRunPing = New-Object Windows.Forms.Button
$buttonRunPing.Text = "Run Ping"
$buttonRunPing.Location = New-Object Drawing.Point(10, 100)
$buttonRunPing.Add_Click({ RunPingForBothIPs })

# Create a button to reset the form
$buttonReset = New-Object Windows.Forms.Button
$buttonReset.Text = "Reset"
$buttonReset.Location = New-Object Drawing.Point(120, 100)
$buttonReset.Add_Click({ ResetForm })

# Create a text box to display the output
$outputTextBox = New-Object Windows.Forms.TextBox
$outputTextBox.Multiline = $true
$outputTextBox.ScrollBars = "Vertical"
$outputTextBox.Location = New-Object Drawing.Point(10, 140)
$outputTextBox.Size = New-Object Drawing.Size(380, 200)

# Add controls to the form
$form.Controls.Add($labelUsableIP)
$form.Controls.Add($labelGatewayIP)
$form.Controls.Add($textBoxUsableIP)
$form.Controls.Add($textBoxGatewayIP)
$form.Controls.Add($buttonRunPing)
$form.Controls.Add($buttonReset)
$form.Controls.Add($outputTextBox)

# Hide the PowerShell console window
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Window {
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    public const int SW_HIDE = 0;
    public const int SW_SHOW = 5;

    public static void HideConsoleWindow() {
        IntPtr hWnd = FindWindow(null, Console.Title);
        if (hWnd != IntPtr.Zero) {
            ShowWindow(hWnd, SW_HIDE);
        }
    }
}
"@

[Window]::HideConsoleWindow()

# Start the application with Form.ShowDialog()
[void]$form.ShowDialog()