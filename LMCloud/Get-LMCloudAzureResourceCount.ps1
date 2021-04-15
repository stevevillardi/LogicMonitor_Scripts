<# © 2007-2020 - LogicMonitor, Inc. All rights reserved. #>

<#
        .DESCRIPTION
        Connects to Azure and exports resources discovered by LM for use in determining resource license count before onboarding.

        .PARAMETER excludeResourceGroups
        Specify list of resource groups(comma seperated) that you do not want included in discovery, everything resource group not matching the list provided will be discovered. Case insensitive

        .PARAMETER includeResourceGroups
        Specify list of resource groups(comma seperated) that you do want included in discovery, those will be the only resource groups used for discovery. Case insensitive

        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        Outputs a CSV file saved to the current working directory the script is ran from.

        .EXAMPLE
        ./Get-LMCloudAzureResourceCount -includeResourceGroups salesdemo,development
        Only discover resources in the salesdemo and development resource groups

        .EXAMPLE
        ./Get-LMCloudAzureResourceCount -excludeResourceGroups salesdemo,development
        Discover everthing is except the salesdemo and development resource groups

        .EXAMPLE
        ./Get-LMCloudAzureResourceCount
        Discover everything 
    #>

[CmdletBinding(DefaultParameterSetName='Exclude')]
Param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
    [string[]] $excludeResourceGroups, #Will discover all RGs except for those specified

    [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
    [string[]] $includeResourceGroups #Will discover only the RGs specified, excluding everything else
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Function to add to custom object
Function Add-To-Export($subscription,$resourceGroup,$id,$type,$name,$location,$tags){
    #breakdown tag hastable into exportable string, need to cleanup how this works
    $stringTags = $null
    if($tags){
        Foreach ($tag in $tags.GetEnumerator()) {
            $stringTags += "$($tag.Key)=$($tag.Value),"
        }
    }

    #Build custom object for exporting list of resources
    $tempObject = [PSCustomObject]@{
        subscriptionId = $subscription.Id
        subscriptionName = $subscription.Name
        resourceGroup = $resourceGroup
        Type = $type
        Id = $id
        Name = $name
        Location = $location
        Tags = $stringTags
    }
    return $tempObject
}
#Check if required modules are installed and if not install them and load into PS session
Function Load-AzModules($name){
    If(Get-Module -ListAvailable -Name $name) {
        Write-Host "[INFO]: $name module exists, skipping install..."
        Import-Module $name
    } 
    Else {
        Write-Host "[INFO]: $name module does not exist, installing now..."
        Install-Module -Name $name -Force -Confirm:$False
        Import-Module $name
    }
}

#Check if required modules are installed, tested using an older version of Az so some of the standalone modules may be included in Az core now but does not hurt to list them either way.
Write-Host "[INFO]: Checking for required modules..."
Load-AzModules -name Az
Load-AzModules -name Az.CosmosDB
Load-AzModules -name Az.Search
Load-AzModules -name Az.MariaDB
Load-AzModules -name Az.mySQL 
Load-AzModules -name Az.PostgreSQL

#Connect to Azure Environment
Write-Host "[INFO]: Connecting to Azure environment..."
Connect-AzAccount | Out-Null

#Get the date for our output file
$date = Get-Date -UFormat("%m-%d-%y")
$exportFilePath = "$PSScriptRoot\LMCloud_Azure_Resource_Export_$($date).csv"

#If file already exists remove it
if(Test-Path $exportFilePath){
    Remove-Item $exportFilePath -Force
}

#Object for storing our export list
$exportData = @()

#Get each subscription
Write-Host "[INFO]: Collecting resource info..."
$subscriptions = Get-AzSubscription
$subCount = ($subscriptions | Measure-Object).Count
Write-Host "[INFO]: Found ($subCount) subscription/s"

#Loop through subscriptions
Foreach($subscription in $subscriptions){
    Write-Host "[INFO]: Checking subscription: $($subscription.Id)($($subscription.Name))"
    #Set our context for the next set of commands
    Set-AzContext $subscription.Id | Out-Null
    $WarningPreference="SilentlyContinue"

    $resourceGroups = Get-AzResourceGroup
    #Get each resource group we need to check
    If($includeResourceGroups){
        Write-Host "[INFO]: Looking for specific resource groups matching the name/s: $includeResourceGroups"
        $resourceGroups = $resourceGroups | Where-Object { $includeResourceGroups -contains $_.ResourceGroupName }
    }
    ElseIf($excludeResourceGroups){
        Write-Host "[INFO]: Looking for resource groups not matching the name/s: $excludeResourceGroups"
        $resourceGroups = $resourceGroups | Where-Object { $excludeResourceGroups -notcontains $_.ResourceGroupName }
    }

    $resourceGroupCount = ($resourceGroups | Measure-Object).Count
    Write-Host "[INFO]: Found ($resourceGroupCount) resource group/s:"
    $resourceGroups.ResourceGroupName

    #Loop through each group and query each service for resource counts
    Foreach($resourceGroup in $resourceGroups.ResourceGroupName){
        Write-Host "[INFO]: Checking resource group: $resourceGroup"

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Analysis Services"
        #Analysis Services
        $analysisServices = Get-AzAnalysisServicesServer -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $analysisServices){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Analysis Services" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tag
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: API Management"
        #API Management
        $apiManagement = Get-AzApiManagement -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $apiManagement){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "API Management" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: App Service"
        #App Service aka WebApp
        $appServices = Get-AzWebApp -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $appServices){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "App Service" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: App Service Environment"
        #App Service Environment
        $appServiceEnv = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType Microsoft.Web/hostingEnvironments #Need to find a better method, seems to be the onyl way via existing PS modules
        #Loop through each resource and Add to export list
        Foreach($resource in $appServiceEnv){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "App Service Environment" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: App Service Plan"
        #App Service Plan
        $appServicePlan = Get-AzAppServicePlan -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $appServicePlan){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "App Service Plan" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Application Gateway"
        #Application Gateway
        $applicationGateway = Get-AzApplicationGateway -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $applicationGateway){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Application Gateway" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tag
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Application Insights"
        #Application Insights
        $applicationInsights = Get-AzApplicationInsights -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $applicationInsights){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Application Insights" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Automation Account"
        #Automation Account
        $automationAccount = Get-AzAutomationAccount -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $automationAccount){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Automation Account" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Batch Account"
        #Batch Account
        $batchAccount = Get-AzBatchAccount -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $batchAccount){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Batch Account" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Storage Accounts"
        #Storage Accounts (This will breakout Blob,File,Table and Queue storage within each storage account since they are seperate resources nested within a storage account)
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $storageAccount){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Storage Accounts" -id $resource.Id -name $resource.StorageAccountName -location $resource.Location -tags $resource.Tags
        }

        #Loop through each resource and Add to export list
        Foreach($account in $storageAccount){
            #Need to use the storage account context to look into each storage account to list of storage types
            Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Blob Storage"
            $blobStorage = Get-AzStorageContainer -Context $account.Context

            If($blobStorage){
                $blobCount = ($blobStorage | Measure-Object).Count
                $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Blob Storage" -id $account.Id -name "$blobCount Container/s for SA:$($account.StorageAccountName)" -location $account.Location -tags $account.Tags
            }
            Else{
                $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Blob Storage" -id $account.Id -name "Container/s for SA:$($account.StorageAccountName)" -location $account.Location -tags $account.Tags
            }

            Write-Host "[INFO]: Collecting resources in $resourceGroup of type: File Storage"
            $fileShareStorage = Get-AzStorageShare -Context $account.Context

            If($fileShareStorage){
                $fileCount = ($fileShareStorage | Measure-Object).Count
                $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "File Storage" -id $account.Id -name "$fileCount File Share/s for SA:$($account.StorageAccountName)" -location $account.Location -tags $account.Tags
            }
            Else{
                $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "File Storage" -id $account.Id -name "File Share/s for SA:$($account.StorageAccountName)" -location $account.Location -tags $account.Tags
            }

            Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Table Storage"
            $tableStorage = Get-AzStorageTable -Context $account.Context

            If($tableStorage){
                $tableCount = ($tableStorage | Measure-Object).Count
                $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Table Storage" -id $account.Id -name "$tableCount Table/s for SA:$($account.StorageAccountName)" -location $account.Location -tags $account.Tags
            }
            Else{
                $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Table Storage" -id $account.Id -name "Table/s for SA:$($account.StorageAccountName)" -location $account.Location -tags $account.Tags
            }

            Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Queue Storage"
            $queueStorage = Get-AzStorageQueue -Context $account.Context

            If($queueStorage){
                $queueCount = ($queueStorage | Measure-Object).Count
                $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Queue Storage" -id $account.Id -name "$queueCount Queue/s for SA:$($account.StorageAccountName)" -location $account.Location -tags $account.Tags
            }
            Else{
                $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Queue Storage" -id $account.Id -name "Queue/s for SA:$($account.StorageAccountName)" -location $account.Location -tags $account.Tags
            }
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Cognitive Search"
        #Cognitive Search
        $cognitiveSearch = Get-AzSearchService -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $cognitiveSearch){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Cognitive Search" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Cognitive Services"
        #Cognitive Services
        $cognitiveServices = Get-AzCognitiveServicesAccount -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $cognitiveServices){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Cognitive Services" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Cosmos DB"
        #CosmosDB
        $cosmosDB = Get-AzCosmosDBAccount -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $cosmosDB){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Cosmos DB" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Data Factory"
        #Data Factory
        $dataFactory = Get-AzDataFactoryV2 -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $dataFactory){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Data Factory" -id $resource.DataFactoryId -name $resource.DataFactoryName -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: DataLake Analytics"
        #DataLake Analytics
        $dataLakeAnalytics = Get-AzDataLakeAnalyticsAccount -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $dataLakeAnalytics){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "DataLake Analytics" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: DataLake Store"
        #DataLake Store
        $dataLakeStore = Get-AzDataLakeStoreAccount -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $dataLakeStore){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "DataLake Store" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        # Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Event Grid Topics"
        # #Event Grid Topics (Need to figure out how to pull this info correctly)
        # $eventGridTopics = Get-AzEventGridTopic -ResourceGroupName $resourceGroup
        # #Loop through each resource and Add to export list
        # Foreach($resource in $eventGridTopics){
        #     $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Event Grid Topics" -id $resource.Id -name $resource.TopicName -location $resource.Location -tags $resource.Tags
        # }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Event Hub"
        #Event Hub
        $eventHub = Get-AzEventHubNamespace -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $eventHub){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Event Hub" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Express Route Circut"
        #Express Route Circut
        $expressRouteCircut = Get-AzExpressRouteCircuit -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $expressRouteCircut){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Express Route Circut" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Firewalls"
        #Firewalls
        $firewalls = Get-AzFirewall -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $firewalls){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Firewalls" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Front Doors"
        #Front Doors
        $frontDoors = Get-AzFrontDoor -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $frontDoors){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Front Doors" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Functions"
        #Functions
        $functions = Get-AzFunctionApp -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $functions){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Functions" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: HDInsight Clusters"
        #HDInsight Clusters
        $hdInsightClusters = Get-AzHDInsightCluster -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $hdInsightClusters){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "HDInsight Clusters" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: IoT Hub"
        #IoT Hub
        $iotHub = Get-AzIotHub -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $iotHub){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "IoT Hub" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Key Vault"
        #Key Vault
        $keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $keyVault){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Key Vault" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Load Balancers"
        #Load Balancers
        $loadBalancers = Get-AzLoadBalancer -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $loadBalancers){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Load Balancers" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Logic Apps"
        #Logic Apps
        $logicApps = Get-AzLogicApp -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $logicApps){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Logic Apps" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Machine Learning Workspaces"
        #Machine Learning Workspaces (TODO need to figure out how these are calculated)
        $machineLearningWorkspaces = Get-AzMlCommitmentPlan -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $machineLearningWorkspaces){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Machine Learning Workspaces" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: MariaDB Database Server"
        #MariaDB Database Server
        $mariaDB = Get-AzMariaDbServer -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $mariaDB){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "MariaDB Database Server" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: MySQL Database Server"
        #MySQL Database Server
        $mySQL = Get-AzMySqlServer -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $mySQL){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "MySQL Database Server" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Network Interfaces"
        #Network Interfaces
        $networkInterfaces = Get-AzNetworkInterface -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $networkInterfaces){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Network Interfaces" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Notification Hub"
        #Notification Hub
        $notificationHubNamespaces = Get-AzNotificationHubsNamespace -ResourceGroup $resourceGroup
        Foreach($namespace in $notificationHubNamespaces.Name){
            $notificationHub = Get-AzNotificationHub -ResourceGroup $resourceGroup -Namespace $namespace
            #Loop through each resource and Add to export list
            Foreach($resource in $notificationHub){
                $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Notification Hub" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
            }
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: PostgreSQL Database Server"
        #PostgreSQL Database Server
        $postgreSQL = Get-AzPostgreSqlServer -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $postgreSQL){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "PostgreSQL Database Server" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Public IP Address"
        #Public IP Address
        $publicIp = Get-AzPublicIpAddress -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $publicIp){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Public IP Address" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Recovery Services"
        #Recovery Services 
        $recoveryServices = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $recoveryServices){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Recovery Services" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Redis Cache"
        #Redis Cache
        $redisCache = Get-AzRedisCache -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $redisCache){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Redis Cache" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Relay Namespaces"
        #Relay Namespaces
        $relayNamespaces = Get-AzRelayNamespace -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $relayNamespaces){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Relay Namespaces" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Service Bus"
        #Service Bus
        $serviceBus = Get-AzServiceBusNamespace -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $serviceBus){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Service Bus" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Service Fabric Mesh Applications"
        #Service Fabric Mesh Applications (need to check if this is an accurate way to grab resource counts, need reference resource to verify)
        $serviceFabricClusters = Get-AzServiceFabricCluster -ResourceGroupName $resourceGroup
        Foreach($cluster in $serviceFabricClusters.Name){
            $serviceFabric = Get-AzServiceFabricApplication -ResourceGroupName $resourceGroup -ClusterName $cluster
            #Loop through each resource and Add to export list
            Foreach($resource in $serviceFabric){
                $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Service Fabric Mesh Applications" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
            }
        }

        #SQL Resources
        $sqlServer = Get-AzSqlServer -ResourceGroupName $resourceGroup
        Foreach($server in $sqlServer.ServerName){
            Write-Host "[INFO]: Collecting resources in $resourceGroup of type: SQL Database"
            #SQL Database
            $sqlDatabase = Get-AzSqlDatabase -ResourceGroupName $resourceGroup -ServerName $server
            #Loop through each resource and Add to export list
            Foreach($resource in $sqlDatabase){
                if($resource.DatabaseName -eq "master"){
                    $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "SQL Database" -id $resource.ResourceId -name $resource.DatabaseName -location $resource.Location -tags $resource.Tags
                }
            }

            Write-Host "[INFO]: Collecting resources in $resourceGroup of type: SQL Elastic Pools"
            #SQL Elastic Pools
            $sqlElasticPool = Get-AzSqlElasticPool -ResourceGroupName $resourceGroup -ServerName $server
            #Loop through each resource and Add to export list
            Foreach($resource in $sqlElasticPool){
                $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "SQL Elastic Pools" -id $resource.ResourceId -name $resource.ElasticPoolName -location $resource.Location -tags $resource.Tags
            }
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: SQL Managed Instances"
        #SQL Managed Instances
        $sqlManagedInstances = Get-AzSqlInstance -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $sqlManagedInstances){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "SQL Managed Instances" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Stream Analytics"
        #Stream Analytics
        $streamAnalytics = Get-AzStreamAnalyticsJob -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $streamAnalytics){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Stream Analytics" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Virtual Machine"
        #Virtual Machine
        $virtualMachine = Get-AzVM -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $virtualMachine){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Virtual Machine" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Virtual Machine ScaleSet"
        #Virtual Machine ScaleSet
        $virtualMachineScaleSet = Get-AzVmss -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $virtualMachineScaleSet){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Virtual Machine ScaleSet" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Virtual Machine ScaleSet VM"
        #Virtual Machine ScaleSet VM
        $virtualMachineScaleSetVM = Get-AzVmssVM -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $virtualMachineScaleSetVM){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Virtual Machine ScaleSet VM" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }

        Write-Host "[INFO]: Collecting resources in $resourceGroup of type: Virtual Network Gateway"
        #Virtual Network Gateway
        $virtualNetworkGateway = Get-AzVirtualNetworkGateway -ResourceGroupName $resourceGroup
        #Loop through each resource and Add to export list
        Foreach($resource in $virtualNetworkGateway){
            $exportData += Add-To-Export -subscription $subscription -resourceGroup $resourceGroup -type "Virtual Network Gateway" -id $resource.Id -name $resource.Name -location $resource.Location -tags $resource.Tags
        }
    }
    $WarningPreference="Continue"
}

#Export results, seems like some deduplication may be needed before the final export since some resources show up under multiple resource types but should be a close approximaiton to what LM would pick up
Write-Host "[INFO]: Exporting Results..."

$exportData | Sort-Object -Property Type | Export-Csv -NoTypeInformation -Path $exportFilePath
Write-Host "[INFO]: Results exported to: $exportFilePath"

#Logout of Az Sessions once complete 
Disconnect-AzAccount | Out-Null