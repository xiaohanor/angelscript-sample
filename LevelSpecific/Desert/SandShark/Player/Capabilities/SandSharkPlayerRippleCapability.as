class USandSharkPlayerRippleCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"SandSharkRipples");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 110;

	UHazeMovementComponent MoveComp;
	USandSharkPlayerComponent PlayerComp;
	UDynamicWaterEffectDecalComponent RippleComp;

	float OriginalStrength;
	float OriginalContrast;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		PlayerComp = USandSharkPlayerComponent::Get(Player);
		RippleComp = UDynamicWaterEffectDecalComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PlayerComp.bHasTouchedSand)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!PlayerComp.bHasTouchedSand)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RippleComp.Strength = 1.5;
		RippleComp.Contrast = 2.0;
		RippleComp.bOnlyActiveInSurfaceVolumes = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RippleComp.Strength = OriginalStrength;
		RippleComp.Contrast = OriginalContrast;
		RippleComp.bOnlyActiveInSurfaceVolumes = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}