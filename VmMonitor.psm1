<#
	Anass Janah - Devoir 1
	En contribution Avec : Maougnon Sosthene Hounsa et Hamza Harouaka 
	Version: 2.0
	VmMonitor module : ce module est dans le cadre du devoir 1 du cours CR430.
					   Il sert à survailler des machines virtuelles Azure
#>

function Show-Menu {
	param (
		[string]$Title = 'Surveillance des VMs Azure - Menu principal'
	)
	Clear-Host
	Write-Host "================ $Title ================"
    
	Write-Host "1: Afficher la consomation du CPU d'une VM."
	Write-Host "2: Demmarer toutes les VMs eteintes"
	Write-Host "3: Verifier Etat Antimalware VM Windows"
	Write-Host "Q: Quitter."
}

function Show-CPUsageVmAz {

	Get-AzVM | Format-List -Property Name, ResourceGroupName
	
	# cacher les avertissements
	$warningPreference = "SilentlyContinue"
	$vmname = Read-Host -Prompt "Entrez le nom de la VM parmi ceux listees plus haut: "
	$vmaz = Get-AzVM -VMName $vmname
	$AverageCPU = ((Get-AzMetric -ResourceId $vmaz.id -TimeGrain 00:01:00 -DetailedOutput -MetricNames "Percentage CPU").Data.Average | Measure-Object -Average).Average
	$formatCpuPerc = "{0:P}" -f $AverageCPU
	if ($AverageCPU -ge 0.7) {
		Write-Host "Utilisation du CPU haute"-ForegroundColor darkred -BackgroundColor white
		Write-Host "Le pourcentage d'utilisation CPU durant la derniere heure est : " $formatCpuPerc -ForegroundColor DarkYellow
	}
	else {
		Write-Host "Utilisation du CPU normal"-ForegroundColor darkgreen -BackgroundColor white
		Write-Host "Le pourcentage d'utilisation CPU durant la derniere heure est : " $formatCpuPerc -ForegroundColor DarkYellow
	}
	
}

function Start-VmAz {
	
	$vmList = Get-AzureRmVm -Status
	foreach ($vm in $vmList) {
		$vmName = $vm.Name
		if ($vm.PowerState -ne 'VM running') {
			Write-Host "Demarage de $vmName ..." 
			Start-AzureRmVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName
			Write-Host "$vmName est demarree maintenant!" 
		}
		else {
			Write-Host "$vmName est deja demarree!"
		}
	}
	
}

function CheckAntMalWinAzVm {
	
	param(
    
		[Parameter(Mandatory)]
    
		[ValidateNotNullOrEmpty()]
    
		[string]$ResourceGroupName
	
	)
		
	$VMs = Get-AzureRmVM -ResourceGroupName $ResourceGroupName
						
	foreach ($vm in $VMs) {
		$vmOs = $vm.StorageProfile.OsDisk.OsType
		if ( $vmOs -eq "Windows") {				
			try {						
				$ErrorActionPreference = 'silentlycontinue'
				$avExtension = Get-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $vm.name -Name "IaaSAntimalware"					
					
				if ($null -eq $avExtension) {
					write-host "IaaSAntimalware not Installed on " $vm.name
							
					$location = " Canada Central "
					$typeHandlerVer = "1.3"
					
					write-Host "Installing Antimalware on " $vm.name " ......." 
					Set-AzureRmVMExtension -ResourceGroupName $resourceGroupName -VMName $vm.Name -Name "IaaSAntimalware" -Publisher "Microsoft.Azure.Security" -ExtensionType "IaaSAntimalware" -typeHandlerVer $typeHandlerVer -location $location
					write-host "IaaSAntimalware Successfuly Installed "
				}
				Else {
					write-host "Existing" $avExtension.name" Already Installed on" $vm.name -ForegroundColor Green
				}					
						
						
			}
				
			catch {
				Write-Warning $_
			}
			
		}
		else {
			Write-Host "Le SE de la VM $($vm.name) est $vmOs. Cette fonction est uniquement pour les VM Windows"
		} 			
	}				
}


function Start-Menu {
	do {
		Show-Menu
		$selection = Read-Host -Prompt "Entrez votre choix: "
		try {
			switch ($selection) {
				'1' {
					Write-Host "vous avez choisi option #1" -ForegroundColor green
					Show-CPUsageVmAz

				} '2' {
					Write-Host "vous avez choisi option #2" -ForegroundColor green
					Start-VmAz
				} '3' {
					Write-Host "vous avez choisi option #3" -ForegroundColor green
					CheckAntMalWinAzVm
				} 
				 
			}
		}
		catch {
			Write-Host "Un probleme est survenue lors de l'excution de la commande. Voici les detail:" -ForegroundColor darkred
			Write-Host $_ -ForegroundColor darkyellow
		}
		pause
	}
	until ($selection -eq 'q')
}

# pour rendre les fonctions disponibles comme une commande dans powershell
Export-ModuleMember -Function Start-Menu, Show-CPUsageVmAz, Start-VmAz, CheckAntMalWinAzVm