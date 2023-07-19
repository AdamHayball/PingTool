Add-Type -AssemblyName System.Net
Add-Type -AssemblyName System.Windows.Forms

function RunPing {
    param($ipAddress)

    $pingResults = ""

    $pingSender = New-Object System.Net.NetworkInformation.Ping
    $pingOptions = New-Object System.Net.NetworkInformation.PingOptions
    $latencies = @()

    for ($i = 0; $i -lt 200; $i++) {
        $reply = $pingSender.Send($IPAddress, 1000, [byte[]]::new(32), $pingOptions)

        if ($reply.Status -eq 'Success') {
            $latencies += $reply.RoundtripTime
        } else {
            $pingResults += "Request timed out.`n"
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

    # Clear the output text box
    $outputTextBox.Text = ""

    # Validate the input to ensure valid IP addresses are provided
    if ([System.Net.IPAddress]::TryParse($usableIP, [ref]$null) -and [System.Net.IPAddress]::TryParse($gatewayIP, [ref]$null)) {
        # Run the script for the usable IP
        $outputTextBox.Text += "Results for Usable IP ($usableIP):`n"
        $outputTextBox.Text += RunPing $usableIP

        # Add a separator
        $outputTextBox.Text += "`n=================`n"

        # Run the script for the gateway IP
        $outputTextBox.Text += "`nResults for Gateway IP ($gatewayIP):`n"
        $outputTextBox.Text += RunPing $gatewayIP
    } else {
        # Invalid IP address format
        $outputTextBox.Text = "Invalid IP address format. Please enter valid IP addresses."
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
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("User32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

public static void Hide() {
    IntPtr hWnd = GetConsoleWindow();
    if (hWnd != IntPtr.Zero) {
        ShowWindow(hWnd, 0);
    }
}'
[Console.Window]::Hide()

# Start the application with Form.ShowDialog()
[void]$form.ShowDialog()