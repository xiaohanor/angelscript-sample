class ULightSeekerFacingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LightSeekerFacing");

	ALightSeeker LightSeeker;

	ULightSeekerTargetingComponent TargetingComp;
	FHazeAcceleratedQuat TargetRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightSeeker = Cast<ALightSeeker>(Owner);
		TargetingComp = ULightSeekerTargetingComponent::Get(LightSeeker);
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
		TargetRotation.Value = LightSeeker.Head.WorldRotation.Quaternion();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (LightSeeker.Head.ForwardVector.DotProduct(TargetingComp.SyncedDesiredHeadRotation.Value.ForwardVector) > 1.0 - SMALL_NUMBER)
			return;

		TargetRotation.AccelerateTo(TargetingComp.SyncedDesiredHeadRotation.Value.Quaternion(), GetAngularInterpolationDuration(), DeltaTime);
		LightSeeker.Head.SetWorldRotation(TargetRotation.Value);

		if (LightSeeker.bDebugging)
		{
			Debug::DrawDebugLine(LightSeeker.Head.WorldLocation, LightSeeker.Head.WorldLocation + TargetingComp.SyncedDesiredHeadRotation.Value.ForwardVector * 300, FLinearColor::DPink, 10.0);
			//PrintToScreen("Rotating " + MovementAngleDegrees + " / " + TotalAnglesDegrees + " = " + InterpolationPercent);
		}
	}

	private float GetAngularInterpolationDuration() const
	{
		if (LightSeeker.bIsChasing)
			return LightSeeker.ChaseAngularInterpolationDuration;
		if (LightSeeker.bIsInTrance)
			return LightSeeker.TranceAngularInterpolationDuration;
		if (LightSeeker.bIsReturning)
			return LightSeeker.ReturnAngularInterpolationDuration;
		return 1.0;
	}
}