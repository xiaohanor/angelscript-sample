class USkylineBossTankTrailAttackCapability : USkylineBossTankChildCapability
{
//	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankAttack);

	TArray<USkylineBossTankTrailComponent> TrailComponents;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		BossTank.GetComponentsByClass(TrailComponents);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto TrailComponent : TrailComponents)
			TrailComponent.ActivateTrail();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto TrailComponent : TrailComponents)
			TrailComponent.DeactivateTrail();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (auto TrailComponent : TrailComponents)
			TrailComponent.AddExhaustBeamPoint();
	}
}