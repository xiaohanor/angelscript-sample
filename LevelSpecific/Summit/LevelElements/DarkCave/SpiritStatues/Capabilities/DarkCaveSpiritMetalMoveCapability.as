class UDarkCaveSpiritMetalMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ADarkCaveSpiritMetalShield MetalShield;
	UHazeSplineComponent SplineComp;
	FSplinePosition SplinePosition;
	FHazeAcceleratedFloat AccelMoveSpeed;
	FHazeAcceleratedVector AccelVector;
	FHazeAcceleratedQuat AccelQuat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MetalShield = Cast<ADarkCaveSpiritMetalShield>(Owner);
		SplineComp = MetalShield.SplineActor.Spline;
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
		SplinePosition = SplineComp.GetSplinePositionAtSplineDistance(0.0);
		AccelVector.SnapTo(SplinePosition.WorldLocation);
		AccelQuat.SnapTo(SplinePosition.WorldRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = SplinePosition.GetCurrentSplineDistance() / SplineComp.SplineLength;
		float Multiplier  = MetalShield.Curve.GetFloatValue(Alpha);

		if (MetalShield.bSendToTarget)
			AccelMoveSpeed.AccelerateTo(MetalShield.MoveSpeed * Multiplier, 0.75, DeltaTime);
		else
			AccelMoveSpeed.AccelerateTo(-MetalShield.MoveSpeed * Multiplier, 0.75, DeltaTime);

		SplinePosition.Move(AccelMoveSpeed.Value * DeltaTime);
		AccelVector.AccelerateTo(SplinePosition.WorldLocation, 1.5, DeltaTime);
		AccelQuat.AccelerateTo(SplinePosition.WorldRotation, 1.5, DeltaTime);

		MetalShield.ActorLocation = AccelVector.Value;
		MetalShield.ActorRotation = AccelQuat.Value.Rotator();
	}
};