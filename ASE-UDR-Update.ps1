# Get current management addresses for Azure App Service Environmennt and update route table to match
# Init Variables:
# Resource Group Name
$rg = "Resource-Group-Name"
# Route Table Name
$rt = "UDRT-Name"
# Azure Region
$location = "westus-or-other-region-name"
# Azure Subscription ID
$subscriptionID = "azure-subscription-id"
# ASE name
$aseName = "ASE-name"

# Get current management addresses -
$jsondata = az rest --method Get --uri https://management.azure.com/subscriptions/$subscriptionID/resourceGroups/$rg/providers/Microsoft.Web/hostingEnvironments/$aseName/inboundnetworkdependenciesendpoints?api-version=2016-09-01
# Zero Counter
$endpoints = 0
# Initialize Management prefix array
$managementAddresses = @()

# Loop through json to get specific prefixes for routes
forEach ($line in $jsondata) {
  If ($endpoints -eq 1) {
    # Increment counter to stop collecting data after the first close bracket
    If ($line -eq '      ],' ) {
      $endpoints++
    } else {
      $line
      # Trim whitespace and trailing comma before adding prefix to the array
      $managementAddresses += $line.Trim().TrimEnd(",")
    }
  }
  # Increment the counter to start collecting data after the first endpoints and open bracket
  If ($line -eq '      "endpoints": [') {
    $endpoints ++
  }
}

# Get routes in current route table
$currentRoutes = az network route-table route list -g $rg --route-table-name $rt | Select-String -Pattern 'addressPrefix' 
# Initialize array to store current routes
$currentRoutesArray = @()
# Clean up currentRoutes data and store in array to same schema as managementAddresses
foreach ($prefix in $currentRoutes) {$prefix=$prefix.ToString(); $currentRoutesArray += $prefix.split(':')[1].trim().TrimEnd(",")}

# Initialize newRoutes array
$newRoutes=@()
# Compare managementRoutes obtained for the ASE with current routes in the route table.  Add new incremental prefixes to newRoutes array
$newRoutes=Compare-Object -ReferenceObject $currentRoutesArray -DifferenceObject $managementAddresses -passthru | ?{$_.sideIndicator -eq "=>"}

# loop through newRoutes array
foreach ($address in $newRoutes) {
    # Ensure the white space and commas are removed
    $network = $address.Trim().TrimEnd(",")
    # Create a usable name for the route
    $networkname = $network -replace '/','_'
    # Create a new route for each object in the newRoutes array
    az network route-table route create -g $rg --route-table-name $rt -n $networkname --next-hop-type Internet --address-prefix $network
}