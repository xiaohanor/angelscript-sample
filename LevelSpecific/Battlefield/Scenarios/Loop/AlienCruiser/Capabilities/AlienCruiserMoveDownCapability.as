class UAlienCruiserMoveDownCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AAlienCruiser Cruiser;

	float Alpha;
	float MoveDuration = 3.0;
	bool bShouldDeactivate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cruiser = Cast<AAlienCruiser>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bShouldDeactivate)
			return false;
		
		if (!Cruiser.bShouldMoveDown)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bShouldDeactivate)
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
		Alpha = Math::Saturate(ActiveDuration / MoveDuration);
		Cruiser.ActorLocation = Math::Lerp(Cruiser.StartDownLocation, Cruiser.TargetDownLocation, Alpha);
		Cruiser.MoveDownAlpha = Alpha;
		
		if (Alpha == 1)
			bShouldDeactivate = true;
	}
};