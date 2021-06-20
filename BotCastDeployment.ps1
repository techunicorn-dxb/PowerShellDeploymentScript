#install azure module
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber

#Declare Variables
$TenantID = ""
$SubscriptionID = ""
$RGName = "" #leave empty if we need to create one
$ServiceEmailAccount = ""
$TestTeamId = "" #leave this empty to skip, can configure later as well
$resourcesPrefix = "" #usually customer shortname
$workingFolderPath = "" #path to createfolder and create zips
$githubManifestImagesUrl = "https://raw.githubusercontent.com/techunicorn-dxb/ARM-Templates/main/BotCast"
$TemplateUri = "https://raw.githubusercontent.com/techunicorn-dxb/ARM-Templates/main/BotCast/armtemplate.json"

#connect to Azure Account
Connect-AzAccount -ServicePrincipal -Credential (Get-Credential) -Tenant $tenantId -Subscription $SubscriptionID

#parameters
$parameters = @{
    'senderEmail' = $ServiceEmailAccount
    'clientId' = $SPCreds.UserName
    'clientSecret' = $SPCreds.Password
    'tenantId' = $TenantID
    'installationFunctionAppName' = $resourcesPrefix + 'botcastinstallationfa'
    'notificationFunctionAppName' = $resourcesPrefix + 'botcastnotificationfa'
    'editFunctionAppName' = $resourcesPrefix + 'botcasteditfa'
    'deleteFunctionAppName' = $resourcesPrefix + 'deleteFunctionAppName'
    'webAppBotName' = $resourcesPrefix + 'botcastwab'
    'storageAccountName' = $resourcesPrefix + 'botcastsa'
}

#Add test team if passed
if(!$TestTeamId)
{
  $parameters.add( "testTeamId", $TestTeamId )
}

#if rg  not present
if(!$RGName)
{
  $RGName = $resourcesPrefix + '-BotCastRG'
  New-AzResourceGroup -Name $RGName -Location "West Europe"
}

#if fails - run from here again
try{
    #deploy
    $deployment = New-AzResourceGroupDeployment `
      -Name botcastTemplateDeployment `
      -ResourceGroupName $RGName `
      -TemplateUri $TemplateUri `
      -TemplateParameterObject $parameters `
      -Verbose `
      -ErrorAction Stop
}
catch
{
     #if fails delete RG
     Remove-AzResourceGroup -Name $RGName
}

#get Manifest
$userManifest = $deployment.Outputs['userManifest'].Value -replace "`n"," " -replace "✔","->"
$adminManifest = $deployment.Outputs['adminManifest'].Value -replace "`n"," " -replace "✔","->"

#create folder if not exist
New-Item -ItemType Directory -Force -Path $workingFolderPath

#create usermanifest folder
New-Item -ItemType Directory -Force -Path ("{0}\userManifest" -f $workingFolderPath)

#create adminmanifest folder
New-Item -ItemType Directory -Force -Path ("{0}\adminManifest" -f $workingFolderPath)

#create usermanifest json
New-Item ("{0}\manifest.json" -f ("{0}\userManifest" -f $workingFolderPath))
Set-Content ("{0}\manifest.json" -f ("{0}\userManifest" -f $workingFolderPath)) $userManifest

#create adminmanifest json
New-Item ("{0}\manifest.json" -f ("{0}\adminManifest" -f $workingFolderPath))
Set-Content ("{0}\manifest.json" -f ("{0}\adminManifest" -f $workingFolderPath)) $adminManifest

#add images
Invoke-WebRequest ("{0}/color.png" -f $githubManifestImagesUrl) -OutFile ("{0}\userManifest\color.png" -f $workingFolderPath)
Invoke-WebRequest ("{0}/color.png" -f $githubManifestImagesUrl) -OutFile ("{0}\adminManifest\color.png" -f $workingFolderPath)

Invoke-WebRequest ("{0}/outline.png" -f $githubManifestImagesUrl) -OutFile ("{0}\userManifest\outline.png" -f $workingFolderPath)
Invoke-WebRequest ("{0}/outline.png" -f $githubManifestImagesUrl) -OutFile ("{0}\adminManifest\outline.png" -f $workingFolderPath)

# Create a zip file
$userCompress = @{
LiteralPath= ("{0}\manifest.json" -f ("{0}\userManifest" -f $workingFolderPath)), ("{0}\userManifest\color.png" -f $workingFolderPath), ("{0}\userManifest\outline.png" -f $workingFolderPath)
CompressionLevel = "Fastest"
DestinationPath = ("{0}\userManifest.zip" -f $workingFolderPath)
}
Compress-Archive @userCompress

$adminCompress = @{
LiteralPath= ("{0}\manifest.json" -f ("{0}\adminManifest" -f $workingFolderPath)), ("{0}\adminManifest\color.png" -f $workingFolderPath), ("{0}\adminManifest\outline.png" -f $workingFolderPath)
CompressionLevel = "Fastest"
DestinationPath = ("{0}\adminManifest.zip" -f $workingFolderPath)
}
Compress-Archive @adminCompress

Write-Output ("BaseUrl: {0}" -f $deployment.Outputs['baseUrl'].Value)
Write-Output ("UserManifest File Path: {0}" -f ("{0}\userManifest.zip" -f $workingFolderPath))
Write-Output ("AdminManifest File Path: {0}" -f ("{0}\adminManifest.zip" -f $workingFolderPath))

#remove extra files
Remove-Item -Force -LiteralPath ("{0}\userManifest" -f $workingFolderPath) -Recurse
Remove-Item -Force -LiteralPath ("{0}\adminManifest" -f $workingFolderPath) -Recurse



