class UBakedDestructionTimeIterateCapability : UHazeCapability
{
	default CapabilityTags.Add(n"BakedDestructionTimeIterateCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ABakedDestructionActor Destructible;

	float FrameCount;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Destructible = Cast<ABakedDestructionActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Destructible.bRunTimeBased)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (FrameCount >= Destructible.MaxDisplayFrame)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FrameCount = 1;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Destructible.bRunTimeBased = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FrameCount += GenericDestructibleSettings::DefaultFrameRate * Destructible.SpeedMultiplier * DeltaTime;
		FrameCount = Math::Clamp(FrameCount, 0, Destructible.MaxDisplayFrame);
		Destructible.SetDynamicMaterialDisplayFrameTimeBased(Math::FloorToInt(FrameCount));
	}
}