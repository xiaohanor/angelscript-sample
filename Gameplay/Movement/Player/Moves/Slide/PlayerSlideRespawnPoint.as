class APlayerSlideRespawnPoint : ARespawnPoint
{
	//This respawn point will automatically calculate and snap camera rotation on respawning

	void OnRespawnTriggered(AHazePlayerCharacter Player) override
	{
		Super::OnRespawnTriggered(Player);
		
		UPlayerSlideComponent PlayerSlideComp = UPlayerSlideComponent::Get(Player);

		if(!bRotatedCamera)
			PlayerSlideComp.SnapDesiredRotationAndPitch();
	}
};