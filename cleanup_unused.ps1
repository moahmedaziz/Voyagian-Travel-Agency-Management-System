$path = "C:\Users\MohamedAbdelazizSaee\Documents\Ferry Bookings\Voyagian\Version2\HTML\Mature\new.html"
$bak = "$path.bak"
Copy-Item $path $bak

$lines = Get-Content $path

function Find-Sub($start, $sub) {
    for ($i = $start; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Contains($sub)) { return $i }
    }
    return -1
}

$remove = @()

# Dead data arrays
foreach ($marker in @('const suppliersData=', 'const performanceRulesData=', 'let supplierIdSequences=')) {
    $s = Find-Sub 0 $marker
    if ($s -ne -1) { $remove += $s }
}

# Dead helper functions
foreach ($marker in @('function getSupplierOptions(', 'function getSalesmanOptions(', 'function getCommissionRuleOptions(')) {
    $s = Find-Sub 0 $marker
    if ($s -ne -1) { $remove += $s }
}

# First/shadowed getProductOptions (3-line definition)
$s = Find-Sub 0 'function getProductOptions('
if ($s -ne -1) { $remove += $s..($s + 2) }

# Leftover airline modal
$s = Find-Sub 0 '<div class="modal-overlay" id="add-airline-modal">'
if ($s -ne -1) {
    $e = Find-Sub ($s + 1) '<div class="modal-overlay" id="add-payroll-operation-modal">'
    if ($e -ne -1) { $remove += $s..($e - 1) }
}

# Clean stale userAccessData entries and supplier state variables
for ($i = 0; $i -lt $lines.Count; $i++) {
    $l = $lines[$i]
    if ($l.Contains('const userAccessData=')) {
        $l = $l -replace [regex]::Escape('{mod:"Master Data",page:"Clients",view:true,add:true,edit:true,del:false},'), ''
        $l = $l -replace [regex]::Escape('{mod:"Master Data",page:"Suppliers",view:true,add:true,edit:true,del:false},'), ''
        $lines[$i] = $l
    }
    if ($l -match '^\s*let selectedUserIdx') {
        $l = $l -replace [regex]::Escape('let selectedSupplierIdx=null; '), ''
        $l = $l -replace [regex]::Escape('let currentSupplierContacts=[]; '), ''
        $l = $l -replace [regex]::Escape('let currentSupplierBanks=[]; '), ''
        $l = $l -replace [regex]::Escape('let currentSupplierContracts=[]; '), ''
        $l = $l -replace [regex]::Escape("let currentSupplierLookupType=''; "), ''
        $l = $l -replace [regex]::Escape('let supplierLookupList=[]; '), ''
        $lines[$i] = $l
    }
}

$remove = $remove | Select-Object -Unique
$newLines = for ($i = 0; $i -lt $lines.Count; $i++) { if ($remove -notcontains $i) { $lines[$i] } }
$newLines | Set-Content $path -Encoding UTF8

Remove-Item $bak

Write-Host "Removed $($remove.Count) lines"
Write-Host "New total $($newLines.Count) lines"
