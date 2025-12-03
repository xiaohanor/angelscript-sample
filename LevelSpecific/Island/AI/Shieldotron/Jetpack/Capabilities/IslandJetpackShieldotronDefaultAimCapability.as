class UIslandJetpackShieldotronDefaultAimCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"DefaultAim");

	default TickGroup = EHazeTickGroup::Gameplay;

	UBasicAIAnimationComponent AnimComp;
	UIslandJetpackShieldotronAimComponent AimComp;
	FHazeAcceleratedFloat AccPitch;
	FHazeAcceleratedFloat AccYaw;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		AimComp = UIslandJetpackShieldotronAimComponent::Get(Owner);
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
		AccPitch.SnapTo(AnimComp.AimPitch.Get());
		AccYaw.SnapTo(AnimComp.AimYaw.Get());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (AimComp.bClearDefaultAimOnDeactivated)
		{
			AnimComp.AimPitch.Clear(this);
			AnimComp.AimYaw.Clear(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccPitch.AccelerateTo(AimComp.DesiredPitch, 0.5, DeltaTime);
		AccYaw.AccelerateTo(AimComp.DesiredYaw, 0.5, DeltaTime);
		
		AnimComp.AimPitch.Apply(AccPitch.Value, this, EInstigatePriority::Normal);
		AnimComp.AimYaw.Apply(AccYaw.Value, this, EInstigatePriority::Normal);
	}
};