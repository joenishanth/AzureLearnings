#  Azure CLI Task: Create Resource group
az group create -l centralus -n owasp_grp

# Azure CLI T%ask: Create Storage container
az storage account create -g owasp_grp -n owaspstore1000 -l centralus --sku Standard_LRS
az storage share create -n security --account-name owaspstore1000

# Azure CLI Task: Create Azure Container Instance
az storage account keys list -g owasp_grp --account-name owaspstore1000 --query "[0].value" --output tsv > temp.txt
$content = Get-Content temp.txt -First 1
$key = '"{0}"' -f $content
 
Write-Output "https://stagingapp1000.azurewebsites.net"> url.txt
$url = Get-Content url.txt -First 1
$completeurl = '"{0}"' -f $url
 
$ZAP_COMMAND="/zap/zap-baseline.py -t $completeurl -x OWASP-ZAP-Report.xml"
 
az container create -g owasp_grp -n owasp --image owasp/zap2docker-stable --ip-address public --ports 8080 --azure-file-volume-account-name owaspstore1000 --azure-file-volume-account-key $key --azure-file-volume-share-name security --azure-file-volume-mount-path /zap/wrk/ --command-line $ZAP_COMMAND

# Azure CLI Task: Downloading Report

az storage account keys list -g owasp_grp --account-name owaspstore1000 --query "[0].value" --output tsv > temp.txt
$content = Get-Content temp.txt -First 1
$key = '"{0}"' -f $content
 
az storage file download --account-name owaspstore1000 --account-key $key -s security -p OWASP-ZAP-Report.xml --dest %SYSTEM_DEFAULTWORKINGDIRECTORY%\OWASP-ZAP-Report.xml

# Powershell task: Converting Test Report5
$XslPath = "$($Env:SYSTEM_DEFAULTWORKINGDIRECTORY)\_newapp1000\demoweb20000\OWASPToNUnit3.xslt"
$XmlInputPath = "$($Env:SYSTEM_DEFAULTWORKINGDIRECTORY)\OWASP-ZAP-Report.xml"
$XmlOutputPath = "$($Env:SYSTEM_DEFAULTWORKINGDIRECTORY)\Converted-OWASP-ZAP-Report.xml"
$XslTransform = New-Object System.Xml.Xsl.XslCompiledTransform
$XslTransform.Load($XslPath)
$XslTransform.Transform($XmlInputPath, $XmlOutputPath)