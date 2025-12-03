class USkylineTorHammerHurtReactionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HurtReaction");
	USkylineTorHammerComponent HammerComp;
	USkylineTorHammerPivotComponent PivotComp;

	float Duration = 0.5;
	FHazeAcceleratedRotator AccRotation;
	FRotator OriginalRotation;
	FRotator TargetRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		PivotComp = USkylineTorHammerPivotComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HammerComp.bDamaged)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccRotation.SnapTo(PivotComp.Pivot.ActorRotation);
		OriginalRotation = PivotComp.Pivot.ActorRotation;
		TargetRotation = OriginalRotation;
		TargetRotation = OriginalRotation + FRotator(0, 0, 25);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HammerComp.bDamaged = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration > Duration / 2)
			TargetRotation = OriginalRotation;

		AccRotation.SpringTo(TargetRotation, 500, 0.2, DeltaTime);
		PivotComp.Pivot.ActorRotation = AccRotation.Value;
	}
}