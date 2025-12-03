class UBattleCruiserEnterSideViewCapability : UHazeCapability
{
	default CapabilityTags.Add(n"BattleCruiserEnterSideViewCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ABattleCruiserCannon Cannon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cannon = Cast<ABattleCruiserCannon>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Cannon.bEnteredCannon)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Cannon.bEnteredCannon)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}