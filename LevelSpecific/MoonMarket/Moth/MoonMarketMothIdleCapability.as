class UMoonMarketMothIdleCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMoonMarketMoth Moth;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Moth = Cast<AMoonMarketMoth>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Moth.bHasBeenRidden)
			return false;

		if(Moth.IsBeingRidden())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Moth.IsBeingRidden())
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
		// float ZOffset = Math::Sin(ActiveDuration * Moth.Settings.IdleBobSpeed) * Moth.Settings.IdleBobStrength;
		// Owner.AddActorWorldOffset(FVector::UpVector * ZOffset * DeltaTime);
	}
};