# AWS Cost Report Script
Write-Host "AWS Cost Report for Cloud Portfolio Project" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

# Get current month costs
$startDate = (Get-Date -Day 1).ToString('yyyy-MM-dd')
$endDate = (Get-Date).ToString('yyyy-MM-dd')

# Get cost and usage
$costs = aws ce get-cost-and-usage `
    --time-period Start=$startDate,End=$endDate `
    --granularity MONTHLY `
    --metrics "UnblendedCost" `
    --group-by Type=DIMENSION,Key=SERVICE `
    --output json | ConvertFrom-Json

Write-Host "`nCosts by Service:" -ForegroundColor Yellow
foreach ($result in $costs.ResultsByTime[0].Groups) {
    $service = $result.Keys[0]
    $amount = [math]::Round([double]$result.Metrics.UnblendedCost.Amount, 2)
    if ($amount -gt 0) {
        Write-Host "  $service: `$$amount" -ForegroundColor Green
    }
}

# Get total
$total = aws ce get-cost-and-usage `
    --time-period Start=$startDate,End=$endDate `
    --granularity MONTHLY `
    --metrics "UnblendedCost" `
    --output json | ConvertFrom-Json

$totalAmount = [math]::Round([double]$total.ResultsByTime[0].Total.UnblendedCost.Amount, 2)
Write-Host "`nTotal Month-to-Date: `$$totalAmount" -ForegroundColor Cyan

# Check tagged resources
Write-Host "`nTagged Resources:" -ForegroundColor Yellow
$taggedCosts = aws ce get-cost-and-usage `
    --time-period Start=$startDate,End=$endDate `
    --granularity MONTHLY `
    --metrics "UnblendedCost" `
    --filter '{
        "Tags": {
            "Key": "Project",
            "Values": ["cloud-portfolio"]
        }
    }' `
    --output json 2>$null | ConvertFrom-Json

if ($taggedCosts) {
    $taggedAmount = [math]::Round([double]$taggedCosts.ResultsByTime[0].Total.UnblendedCost.Amount, 2)
    Write-Host "  Project 'cloud-portfolio': `$$taggedAmount" -ForegroundColor Green
}
