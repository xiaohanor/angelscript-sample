class UGentlemanCostTeam : UHazeTeam
{
	FTimerHandle UpdateSettingsTimer;
	TPerPlayer<UGentlemanComponent> GentlemanComps;
	TPerPlayer<UGentlemanCostSettings> GentlemanCostSettings;

	UFUNCTION(BlueprintOverride)
	void OnMemberJoined(AHazeActor Member)
	{
		Super::OnMemberJoined(Member);

		GentlemanComps[Game::Mio] = UGentlemanComponent::GetOrCreate(Game::Mio);
		GentlemanComps[Game::Zoe] = UGentlemanComponent::GetOrCreate(Game::Zoe);
		
		GentlemanCostSettings[Game::Mio] = UGentlemanCostSettings::GetSettings(Game::Mio);
		GentlemanCostSettings[Game::Zoe] = UGentlemanCostSettings::GetSettings(Game::Zoe);

		if(!UpdateSettingsTimer.IsTimerActive())
			UpdateSettingsTimer = Timer::SetTimer(this, n"UpdateSettings", 0.5, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnMemberLeft(AHazeActor Member)
	{
		Super::OnMemberLeft(Member);
		if(GetMembers().Num() == 0)
		{
			UpdateSettingsTimer.ClearTimer();
		}
	}

	UFUNCTION()
	private void UpdateSettings()
	{
		for(AHazePlayerCharacter Player: Game::Players)
		{
			GentlemanComps[Player].SetMaxAllowedClaimants(GentlemanToken::Cost, GentlemanCostSettings[Player].MaxAggressionLevel);
		}			
	}
}