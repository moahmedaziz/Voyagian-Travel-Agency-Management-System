$path = 'C:\Users\MohamedAbdelazizSaee\Documents\Ferry Bookings\Voyagian\Version2\HTML\Mature\coa-list.txt'
$outPath = 'C:\Users\MohamedAbdelazizSaee\Documents\Ferry Bookings\Voyagian\Version2\HTML\Mature\coa-data.js'
$lines = Get-Content -Path $path
$regex = '^(?<code>\S+)\s+(?<level>Group|Sub Group|Category|Ledger Account)\s+(?<name>.+)$'
$items = @()
$lastAtLevel = @{}
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i].Trim()
    if ($line -notmatch $regex) { continue }
    $code = $matches['code']
    $levelName = $matches['level']
    $name = $matches['name'].Trim()
    $level = switch ($levelName) {
        'Group' { 1 }
        'Sub Group' { 2 }
        'Category' { 3 }
        'Ledger Account' { 4 }
    }
    $parentLevel = 0
    for ($p = $level - 1; $p -ge 1; $p--) { if ($lastAtLevel[$p]) { $parentLevel = $p; break } }
    $parent = if ($parentLevel -gt 0) { $lastAtLevel[$parentLevel] } else { $null }
    $parentId = if ($parent) { $parent.id } else { $null }
    $parentCode = if ($parent) { $parent.code } else { $null }
    $parentName = if ($parent) { $parent.name } else { $null }
    for ($l = $level + 1; $l -le 4; $l++) { $lastAtLevel[$l] = $null }
    $item = [PSCustomObject]@{
        id = "coa-$i"
        code = $code
        name = $name
        level = $level
        levelName = $levelName
        parentId = $parentId
        parentCode = $parentCode
        parentName = $parentName
        currency = 'USD'
        status = 'Active'
        isSystem = $true
        allowManualJournals = ($level -eq 4)
        controlAccount = $false
        balance = 0
        currentBalance = 0
        children = @()
    }
    $lastAtLevel[$level] = $item
    $layers = @($null, $null, $null, $null)
    for ($l = 1; $l -le 4; $l++) {
        if ($l -le $level -and $lastAtLevel[$l]) {
            $layers[$l - 1] = $lastAtLevel[$l].name
        }
    }
    $item | Add-Member -NotePropertyName layer1 -NotePropertyValue $layers[0]
    $item | Add-Member -NotePropertyName layer2 -NotePropertyValue $layers[1]
    $item | Add-Member -NotePropertyName layer3 -NotePropertyValue $layers[2]
    $item | Add-Member -NotePropertyName layer4 -NotePropertyValue $layers[3]
    $items += $item
}
$map = @{}
$roots = @()
foreach ($it in $items) { $map[$it.id] = $it }
foreach ($it in $items) {
    if ($it.parentId -and $map.ContainsKey($it.parentId)) {
        $map[$it.parentId].children += $it
    } else {
        $roots += $it
    }
}
$dataJson = ($items | Select-Object -Property id, code, name, level, levelName, parentId, parentCode, parentName, layer1, layer2, layer3, layer4, currency, status, isSystem, allowManualJournals, controlAccount, balance, currentBalance | ConvertTo-Json -Depth 10 -Compress)
$out = @"
const coaData = $dataJson;
function buildCOATree(data){
    const map={}, roots=[];
    data.forEach(n=>{ map[n.id]=n; n.children=[]; });
    data.forEach(n=>{ if(n.parentId && map[n.parentId]){ map[n.parentId].children.push(n); } else { roots.push(n); } });
    return roots;
}
"@
Set-Content -Path $outPath -Value $out
