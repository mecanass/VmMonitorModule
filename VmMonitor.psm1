<#
	Anass Janah - Devoir 1
	Version: 1.0
	VmMonitor module : ce module est dans le cadre du devoir 1 du cours CR430.
					   Il sert à survailler la performance des machines virtuelles
					   Hyper-v.
#>
function Show-Menu {
    param (
        [string]$Title = 'Survaillance de la performance des VM - Menu'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1: Afficher la consomation de la mémoire vive."
    Write-Host "2: Option 2."
    Write-Host "3: Option 3."
    Write-Host "Q: Quitter."
}

function Memoire-Vive{
	#TODO écrire la fonction qui affiche en permanance l'état de la mémoire vive des VM
}


function Start-Menu{
	do
	 {
		Show-Menu
		$selection = Read-Host "Entrez votre choix: "
		switch ($selection)
		{
		'1' {
		Write-Host "vous avez choisi option #1"
		} '2' {
		Write-Host "vous avez choisi option #2"
		} '3' {
		Write-Host "vous avez choisi option #3"
		}
		}
		pause
	 }
	 until ($selection -eq 'q')
}

# pour rendre les fonctions disponibles comme une commande dans powershell
Export-ModuleMember -Function Start-Menu

