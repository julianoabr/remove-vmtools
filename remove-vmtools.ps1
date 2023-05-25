#Requires -Version 3.0
#Requires -RunAsAdministrator

<#
.Synopsis
   Remove VMTOOLS and services
.DESCRIPTION
   Remove VMTOOLS on Windows Server 2003, 2008, 2012, 2016 and 2019
.EXAMPLE
   Insert after create main function
.URL
  https://kb.vmware.com/s/article/1001354
  https://kb.vmware.com/s/article/1010398  
.EXAMPLE
   Must run locally
.CREATEDBY
    Juliano Alves de Brito Ribeiro (Find me at: julianoalvesbr@live.com or https://github.com/julianoabr)
.VERSION INFO
    0.1
.TO THINK
    Seria possível que a vida evoluísse aleatoriamente a partir de matéria inorgânica? Não de acordo com os matemáticos.

    Nos últimos 30 anos, um número de cientistas proeminentes têm tentado calcular as probabilidades de que um organismo de vida livre e unicelular, como uma bactéria, pode resultar da combinação aleatória de blocos de construção pré-existentes. 
    Harold Morowitz calculou a probabilidade como sendo uma chance em 10^100.000.000.000
    Sir Fred Hoyle calculou a probabilidade de apenas as proteínas de amebas surgindo por acaso como uma chance em 10^40.000.

    ... As probabilidades calculadas por Morowitz e Hoyle são estarrecedoras. 
    Essas probabilidades levaram Fred Hoyle a afirmar que a probabilidade de geração espontânea 'é a mesma que a de que um tornado varrendo um pátio de sucata poderia montar um Boeing 747 com o conteúdo encontrado'. 
    Os matemáticos dizem que qualquer evento com uma improbabilidade maior do que uma chance em 10^50 faz parte do reino da metafísica - ou seja, um milagre.1

    1. Mark Eastman, MD, Creation by Design, T.W.F.T. Publishers, 1996, 21-22.

.IMPROVEMENTS NEXT VERSIONS
    0.2 (removal vmtools files inside vmtools folder after reboot - access denied for first run)
    0.3 (run remote)
    0.4 (run on multiple vms)
    0.5 (install new vmtools)
    
#>


function Stop-VmToolsSvc
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [System.String[]]
        $svcListName


    )

foreach ($svcName in $svcListName)
{
       
    $svcObj = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    
    if ($svcObj -eq $null){
    
        Write-Host "Service: $svcName does not exists. Nothing to Do" -ForegroundColor Green

            
    }#if OBJ NULL
    else{
    
        $svcStartType = $svcObj.StartType

        if ($svcStartType -match 'Disabled'){
    
            Write-Host "Service: $svcName is disabled. Nothing to Do" -ForegroundColor Green
    
        }#Verify if Service is disabled
        else{
        
            #START COUNTER
            $svcCounter = 1  
            
            do{
    
                Write-Host "Attempt: $svcCounter de parar o serviço: $svcName" -BackgroundColor Cyan  -ForegroundColor White

                $svcState = (Get-Service -Name $svcName).Status
       
                if ($svcState -eq 'Stopped'){
       
                    Write-Output "The Service $svcName is already Stopped..."

                }
                else{
       
                    Get-Service -Name $svcName | Stop-Service -Verbose

                    Start-Sleep -Seconds 3 -Verbose
              
                }

            $svcCounter ++
       

            }while(($svcState -notlike 'Stopped') -xor ($svcCounter -gt 6))

  
    
        }#Else Service not disabled
        
    
    }#Else OBJ FOUND

   
}#End of ForEach Service

  
}#end of Function

function delete-VmToolsSvc
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [System.String[]]
        $svcListName


    )

foreach ($svcName in $svcListName)
{
        
        $svcObj = Get-Service -Name $svcName -ErrorAction SilentlyContinue


        if ($svcObj -eq $null){
    
            Write-Host "Service: $svcName does not exists. Nothing to Do" -ForegroundColor Green

            
        }#if OBJ NULL
        else{

            #START COUNTER
            $svcCounter = 1
            
            do{
            
                Write-Host "Tentativa: $svcCounter de excluir o serviço: $svcName" -BackgroundColor Cyan  -ForegroundColor White

                $svcToDelete = (Get-WmiObject -Class win32_service -Filter "Name='$svcName'")
       
                if ($svcToDelete.State -match 'Stopped'){
       
                    Write-Output "The Service $svcName is Stopped...I will remove IT"

                    $svcToDelete.Delete()

                }
                elseif ($svcToDelete -match 'Running'){
       
                    Get-Service -Name $svcName | Stop-Service -Verbose

                    Start-Sleep -Seconds 3 -Verbose
              
                }elseif ($svcToDelete -eq $null){
            
                    Write-Host "Service: $svcName was not found. Verifying next..." -ForegroundColor DarkGreen -BackgroundColor White

                    $svcCounter = 5
                            
                }else{
            
                    $svcState = $svcToDelete.State
               
                    Write-Host "Service: $svcName. State: $svcState. I can't remove service in this state. Verify manually" -ForegroundColor Red -BackgroundColor White 
            
                }

                $svcCounter ++
       

            }while(($svcState -notlike 'Stopped') -xor ($svcCounter -gt 4))
            

        }#End of Else OBJ Not Null
 
    
    }#End of ForEach Service

  
}#end of Function

function Get-OSVersion ($hostname, $osBuild)
{
    
    switch -Regex ($osBuild)
    {
        
        '^5.2\.\d{4}\.*' {$osVersion = 'WServer2003'; Write-Host "You are running Windows 2003 Server" -ForegroundColor White -BackgroundColor Green}
        '^6.1\.\d{4}\.*' {$osVersion = 'WServer2008R2'; Write-Host "You are running Windows 2008 Server" -ForegroundColor White -BackgroundColor Green} 
        '^6.[2-3]\.\d{4}\.*' {$osVersion = 'WServer2012'; Write-Host "You are running Windows 2012 or Windows 8" -ForegroundColor White -BackgroundColor Green} 
        '^10.0\.\d{5}\.*' {$osVersion = 'WServer2016AndAbove'; Write-Host "You are running Windows 10, Windows 2016 or Windows 2019" -ForegroundColor White -BackgroundColor Green} 
        Default {$osVersion = 'UnknownWindows'; Write-Host "I can't run on this Windows Version" -ForegroundColor White -BackgroundColor Red} 
    }#end of Switch
   
   
    return $osBuild,$osVersion

}#End of Function Get-OSVersion

function Backup-RegistryKey
{
    [CmdletBinding()]
      Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [System.String[]]
        $registryList

   
    )

$nrOfRegistryItens = $registryList.count

$counterRegName = 0

    for ($counterRegName = 0; $counterRegName -le $nrOfRegistryItens; $counterRegName++)
    { 

        $prefix = 'backupReg'
    
        $suffix = $counterRegName.ToString()    

        $BackupFileReg = $prefix + $suffix + '.reg'
        
        $regKey = $registryList[$counterRegName]

        Start-Process -FilePath "$env:windir\regedit.exe" -ArgumentList "/e $backupFileReg `"$regKey`"" -Verbose
    
    
    }#End of For
    
}#End of Function Backup-RegistryKey

function Delete-RegistryKey
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [System.String[]]
        $registryList

  
    )

    foreach ($registryItem in $registryList)
    {
        

        if ($registryItem -match '^\bHKEY_CLASSES_ROOT\b\\{1}\w+'){
        
            
            $regDelItem = $registryItem -replace 'HKEY_CLASSES_ROOT','HKCR:'

            #Test if path exists
            $pathExists = Test-Path -Path $regDelItem

            if ($pathExists){
            
                Remove-Item -Path $regDelItem -Force -Recurse -Verbose
                
                #Remove-Item -Path $regDelItem -Recurse -WhatIf -Verbose 
            
            }#if path exists
            else{
            
                Write-Host "The registry path:" -ForegroundColor Magenta -NoNewline; Write-Host -NoNewline " $regDelItem" -ForegroundColor Green; Write-Host " was not found." -ForegroundColor Magenta 
            
            }#else path does not exists
        
        
        }#validate path 
        elseif($registryItem -match '^\bHKEY_LOCAL_MACHINE\b\\{1}\w+'){
        
        
            $regDelItem = $registryItem -replace 'HKEY_LOCAL_MACHINE','HKLM:'

               #Test if path exists
            $pathExists = Test-Path -Path $regDelItem

            if ($pathExists){
            
                Remove-Item -Path $regDelItem -Force -Recurse -Verbose
                
                #Remove-Item -Path $regDelItem -Recurse -WhatIf -Verbose  
            
            }#if path exists
            else{
            
                Write-Host "The registry path:" -ForegroundColor Magenta -NoNewline; Write-Host -NoNewline " $regDelItem" -ForegroundColor Green; Write-Host " was not found." -ForegroundColor Magenta 
            
            }#else path does not exists


        }#validate path
        else{
        
        
            Write-Host "The registry path:" -ForegroundColor Magenta -NoNewline; Write-Host -NoNewline " $registryItem" -ForegroundColor Green; Write-Host " is not in KB 1001354." -ForegroundColor Magenta
        
        }#path dos not exists


    }#end of Foreach registry item


}#End of Function

function Delete-VmToolsFolder
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$false,
                   Position=0)]
        $x86Path= "${env:ProgramFiles(x86)}\VMware\VMware Tools",

         [Parameter(Mandatory=$false,
                   Position=1)]
        $x64Path = "$env:ProgramFiles\VMware\VMware Tools"
    )

    $x86pathExists = Test-Path $x86Path

    $x64pathExists = Test-Path $x64Path


    if ($x86pathExists){
    
        $fileList = Get-ChildItem -Path $x86Path -Recurse  
        
        #$fileList | Remove-Item -Recurse -WhatIf -Verbose

        $fileList | Remove-Item -Recurse -Force -Verbose
    
    
    }
    else{
    
        Write-Host "VmTools Folder was not found on x86 path" -ForegroundColor White -BackgroundColor Green
    
    }

    if ($x64pathExists){
    
        $fileList = Get-ChildItem -Path $x64Path -Recurse  
        
        #$fileList | Remove-Item -Recurse -WhatIf

        $fileList | Remove-Item -Recurse -Force -Verbose
    
    }
    else{
    
        Write-Host "VmTools Folder was not found on x64 path" -ForegroundColor White -BackgroundColor Green
    
    }


}#end of Function


################################################################
###################### MAIN SCRIPT #############################

#Create PS Drive for HKEY_CLASSES_ROOT
$driveHKCUExists = Get-PSDrive -Name 'HKCU'

if ($driveHKCUExists){

     Write-Host "PSDRIVE for HKEY_CURRENT_USES already exists..." -ForegroundColor White -BackgroundColor Blue

}
else{
    
    Write-Host "PSDRIVE for HKEY_CURRENT_USES does not exists. I will create one..." -ForegroundColor White -BackgroundColor Magenta

    New-PSDrive -Name 'HKCR' -PSProvider Registry -Root "HKEY_CLASSES_ROOT" -Description "PSDrive for HKEY_CLASSES_ROOT" -Confirm:$false -Verbose

}




#REGISTRY KEYS INFO
#Windows 2003 Registry Keys for 
$w2k3RegKeys = @()

$w2k3RegKeys = 'HKEY_CLASSES_ROOT\Installer\Features\005014B32081E884E91FB41199E24004', 
'HKEY_CLASSES_ROOT\Installer\Products\005014B32081E884E91FB41199E24004',
'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Features\005014B32081E884E91FB41199E24004',
'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Products\005014B32081E884E91FB41199E24004',
'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0B150AC107B12D11A9DD0006794C4E25',
'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{3B410500-1802-488E-9EF1-4B11992E0440}',
'HKEY_LOCAL_MACHINE\SOFTWARE\VMware, Inc.'


$w2k3SvcKeys = @()
$w2k3SvcKeys = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VMTools',
'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VMUpgradeHelper',
'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VMware Physical Disk Helper Service',
'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmvss'


$w2k8R2RegKeys = @()
$w2k8R2RegKeys = 'HKEY_CLASSES_ROOT\Installer\Features\C2A6F2EFE6910124C940B2B12CF170FE',
'HKEY_CLASSES_ROOT\Installer\Products\C2A6F2EFE6910124C940B2B12CF170FE',
'HKEY_CLASSES_ROOT\CLSID\{D86ADE52-C4D9-4B98-AA0D-9B0C7F1EBBC8}',
'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\C2A6F2EFE6910124C940B2B12CF170FE',
'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{FE2F6A2C-196E-4210-9C04-2B1BC21F07EF}'



$w8w2k12RegKeys = @()
$w8w2k12RegKeys = 'HKEY_CLASSES_ROOT\Installer\Features\B634907914A56494B87EA24A33AC1F80',
'HKEY_CLASSES_ROOT\Installer\Products\B634907914A56494B87EA24A33AC1F80',
'HKEY_CLASSES_ROOT\CLSID\{D86ADE52-C4D9-4B98-AA0D-9B0C7F1EBBC8}',
'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Features\B634907914A56494B87EA24A33AC1F80',
'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Products\B634907914A56494B87EA24A33AC1F80',
'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\B634907914A56494B87EA24A33AC1F80',
'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{9709436B-5A41-4946-8BE7-2AA433CAF108}',
'HKEY_LOCAL_MACHINE\SOFTWARE\VMware, Inc.'

$w10w2k16w2k19RegKeys = @()
$w10w2k16w2k19RegKeys = 'HKEY_CLASSES_ROOT\Installer\Features\FABCF247D5EE2B84E959AD50317B5907',
'HKEY_CLASSES_ROOT\Installer\Products\FABCF247D5EE2B84E959AD50317B5907',
'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Features\FABCF247D5EE2B84E959AD50317B5907',
'HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Products\FABCF247D5EE2B84E959AD50317B5907',
'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\FABCF247D5EE2B84E959AD50317B5907',
'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{F32C4E7B-2BF8-4788-8408-824C6896E1BB}',
'HKEY_LOCAL_MACHINE\SOFTWARE\VMware, Inc'

$genericSvcKeys = @()
$genericSvcKeys = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VMTools', 
'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VMUpgradeHelper', 
'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VMware Physical Disk Helper Service',
'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmvss', 
'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VGAuthService', 
'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VMUSBArbService',
'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VMwareCAFCommAmqpListener', 
'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VMwareCAFManagementAgentHost', 
'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CipMsgProxyService' 



$svcListAll = @()
$svcListAll = 'VGAuthService','VMwareCAFCommAmqpListener','VMwareCAFManagementAgentHost','CipMsgProxyService',
'VMTools','VMUSBArbService', 'vmvss', 'VMUpgradeHelper', 'VMware Physical Disk Helper Service'



#MAIN SCRIPT
$rHostName = $env:COMPUTERNAME

$rOsBuild = [System.Environment]::OSVersion.Version.ToString()

$shortOsVersion = ((Get-OSVersion -hostname $rHostName -osBuild $rOsBuild).Get(1))


$pvSCSIControllerExists =  Get-WmiObject -Class win32_pnpsigneddriver | Where-Object -FilterScript {$_.DeviceName -eq 'VMware PVSCSI Controller'}


if ($pvSCSIControllerExists -eq $null){

    Write-Host "VMware PVSCSI Controller driver was not found on this system. Continue with no problem" -ForegroundColor White -BackgroundColor Blue

}
else{

    Write-Host "VMware PVSCSI Controller driver was found on this system." -ForegroundColor White -BackgroundColor Red

    Write-Host "Remember that after configuring the boot disk to use a PVSCSI controller,if you uninstall
VMware tools the VM will fail to boot successfully as it no longer has the required driver installed" -ForegroundColor White -BackgroundColor Red

}

do
{
    
    Write-Host "Do you want to continue? Are you sure?" -ForegroundColor White -BackgroundColor Magenta
    
    $delChoice = Read-Host "Type only (YES) or (NO)"
    
    if ($delChoice -match '^\bYes\b$'){
    
        Write-Host "You choose YES" -ForegroundColor Red

        if ($shortOsVersion -match 'WServer2003'){

            Stop-VmToolsSvc -svcListName $svcListAll

            Backup-RegistryKey -registryList $w2k3RegKeys
        
            Backup-RegistryKey -registryList $w2k3SvcKeys
        
            Delete-RegistryKey -registryList $w2k3RegKeys
        
            Delete-RegistryKey -registryList $w2k3SvcKeys   

            delete-VmToolsSvc -svcListName $svcListAll

            Delete-VmToolsFolder 

        }
        elseif ($shortOsVersion -match 'WServer2008R2'){


            Stop-VmToolsSvc -svcListName $svcListAll

            Backup-RegistryKey -registryList $w2k8R2RegKeys
        
            Backup-RegistryKey -registryList $genericSvcKeys
        
            Delete-RegistryKey -registryList $w2k8R2RegKeys
        
            Delete-RegistryKey -registryList $genericSvcKeys 

            Delete-VmToolsSvc -svcListName $svcListAll

            Delete-VmToolsFolder 

        }
        elseif ($shortOsVersion -match 'WServer2012'){
                
            Stop-VmToolsSvc -svcListName $svcListAll

            Backup-RegistryKey -registryList $w8w2k12RegKeys
        
            Backup-RegistryKey -registryList $genericSvcKeys
        
            Delete-RegistryKey -registryList $w8w2k12RegKeys
        
            Delete-RegistryKey -registryList $genericSvcKeys 

            delete-VmToolsSvc -svcListName $svcListAll

            Delete-VmToolsFolder 

        }
        elseif ($shortOsVersion -match 'WServer2016AndAbove'){


            Stop-VmToolsSvc -svcListName $svcListAll

            Backup-RegistryKey -registryList $w10w2k16w2k19RegKeys
        
            Backup-RegistryKey -registryList $genericSvcKeys
        
            Delete-RegistryKey -registryList $w10w2k16w2k19RegKeys
        
            Delete-RegistryKey -registryList $genericSvcKeys 

            delete-VmToolsSvc -svcListName $svcListAll

            Delete-VmToolsFolder 

        }
        else{

            Write-Host "Unknown Windows Version. I can't deal with it" -ForegroundColor White -BackgroundColor Red

        }

    
    }#end of IF CHOICE
    elseif ($delChoice -match '^\bNo\b$'){
    
        Write-Host "You choose NO" -ForegroundColor Blue

        Exit
    
    }#end of Elseif Choice
    else{
    
        Write-Host "Type only (YES) or (NO), $delChoice is not accepted" -ForegroundColor White -BackgroundColor Red
    
    }#end of Else Choice
    
}
while ($delChoice -notmatch "^(?:Yes\b|No\b)$")
