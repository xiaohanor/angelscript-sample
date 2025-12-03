class UIslandJetpackPhaseWallBlockShootingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UIslandJetpackComponent JetpackComp;

	const float BlockDuration = 0.75;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetpackComp = UIslandJetpackComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		float TimeSince = Time::GetGameTimeSince(JetpackComp.TimeWhenUsedPhasableWall);
		if(TimeSince > BlockDuration)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		float TimeSince = Time::GetGameTimeSince(JetpackComp.TimeWhenUsedPhasableWall);
		if(TimeSince > BlockDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(IslandRedBlueWeapon::IslandRedBlueBlockedWhileInAnimation, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(IslandRedBlueWeapon::IslandRedBlueBlockedWhileInAnimation, this);
	}
}