<#
	Anass Janah - Devoir 1
	En contribution Avec : Maougnon Sosthene Hounsa et Hamza Harouaka 
	Version: 2.0
	VmMonitor module : ce module est dans le cadre du devoir 1 du cours CR430.
					   Il sert à survailler des machines virtuelles Azure
#>
function Show-Menu {
	param (
		[string]$Title = 'Survaillance des VMs Azure - Menu principal'
	)
	Clear-Host
	Write-Host "================ $Title ================" -ForegroundColor blue
    
	Write-Host "1: Afficher la consomation du CPU d'une VM." -ForegroundColor DarkMagenta
	Write-Host "2: Demmarer toutes les VMs eteintes" -ForegroundColor DarkMagenta
	Write-Host "3: Verifier Etat Antimalware VM Windows" -ForegroundColor DarkMagenta
	Write-Host "Q: Quitter." -ForegroundColor DarkMagenta
}

function Show-CPUsageVmAz {

	Get-AzVM | Format-List -Property Name, ResourceGroupName
	
	# cacher les avertissements
	$warningPreference = "SilentlyContinue"
	$vmname = Read-Host "Entrez le nom de la VM parmi ceux listees plus haut: "
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
	
	pause
	Start-Menu
}

function Start-VmAz {
	
	$vmList = Get-AzureRmVm -Status
	foreach ($vm in $vmList) {
		$vmName = $vm.Name
		if ($vm.PowerState -ne 'VM running') {
			Write-Host "Demarage de $vmName ..." -ForegroundColor darkblue
			Start-AzureRmVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName
			Write-Host "$vmName est demarree maintenant!"  -ForegroundColor darkgreen
		}
		else {
			Write-Host "$vmName est deja demarree!"  -ForegroundColor darkgreen
		}
	}
	
	# attendre le signale du user avant de revenir au menu
	pause
	Start-Menu
}

function CheckAntMalWinAzVm {
	
	param(
    
		[Parameter(Mandatory)]
    
		[ValidateNotNullOrEmpty()]
    
		[string]$ResourceGroupName
	

	)
	$Config_String = [IO.File]::ReadAllText('c:\AV.json')
	$VMs = Get-AzureRmVM -ResourceGroupName $ResourceGroupName
	Write-Host $($VMs| Format-Table| Out-String ) -ForegroundColor Blue

	foreach ($vm in $vms) {
		$vmOs = $vm.StorageProfile.OsDisk.OsType
		if ( $vmOs -eq "Windows") {
			$avExtension = Get-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $vm.name -Name IaaSAntimalware
			$publicSettings = ConvertFrom-Json $avExtension.PublicSettings
			#$avExtension.PublicSettings["AntimalwareEnabled"]
			$publicSettings
				
			if ($avExtension.PublicSettings["AntimalwareEnabled"] -eq "False") {
				Write-Host "Installation du antiMalware pour la VM $vm.name" -ForegroundColor DarkYellow
				Set-AzureVMMicrosoftAntimalwareExtension -AntimalwareConfiguration $Config_String | Update-AzureVM
			}
		}
		else {
			Write-Host "Le SE de la VM $($vm.name) est $vmOs. Cette fonction est uniquement pour les VM Windows" -ForegroundColor Darkred
		}
	}
	pause
	Start-Menu
}


function Start-Menu {
	do {
		Show-Menu
		$selection = Read-Host "Entrez votre choix: "
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