class UIslandWalkerUnderneathCapability : UHazeCapability
{
	UIslandWalkerUnderneathComponent UnderneathComp;
	UIslandWalkerPhaseComponent PhaseComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UnderneathComp = UIslandWalkerUnderneathComponent::Get(Owner);
		PhaseComp = UIslandWalkerPhaseComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase != EIslandWalkerPhase::Walking)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.Phase != EIslandWalkerPhase::Walking)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(AHazePlayerCharacter Player: Game::Players)
		{
			bool Underneath = UnderneathComp.UnderneathPlayers.Contains(Player);
			bool WithinDistance = Player.ActorLocation.IsWithinDist(Owner.ActorLocation, 1000);
			if(WithinDistance && !Underneath)
			{
				Player.ApplyCameraSettings(UnderneathComp.UnderneathCameraSettings, 2, this, SubPriority = 60);
				UnderneathComp.UnderneathPlayers.AddUnique(Player);
			}
			else if(!WithinDistance && Underneath)
			{
				Player.ClearCameraSettingsByInstigator(this);
				UnderneathComp.UnderneathPlayers.RemoveSingle(Player);
			}
		}
	}
}