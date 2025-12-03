class USlidingDiscAmbientMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default TickGroup = EHazeTickGroup::Movement;

	ASlidingDisc SlidingDisc;

	FHazeAcceleratedVector AccAmbientLoc;
	FVector AmbientLocTarget = FVector();
	float ChangeLocTargetCooldown = 0.1;

	FHazeAcceleratedQuat AccAmbientRot;
	UHazeMovementComponent MovementComponent;
 
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SlidingDisc = Cast<ASlidingDisc>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
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
	void TickActive(float DeltaTime)
	{
		float OscillationTime = 0.1;

		if (SlidingDisc.GrindingOnHydra != nullptr)
		{
			float Oscillating = Math::Sin(Time::GameTimeSeconds / 0.33);
			const FVector OscillationAxis = (FVector::ForwardVector + FVector::UpVector).GetSafeNormal();
			FQuat AmbientTarget = FQuat(OscillationAxis, Math::DegreesToRadians(Oscillating * 10.0));
			AccAmbientRot.AccelerateTo(AmbientTarget, OscillationTime, DeltaTime);

			ChangeLocTargetCooldown += DeltaTime;
			if (ChangeLocTargetCooldown >= 0.1)
				AmbientLocTarget = FVector::UpVector * Math::RandRange(-150.0, 150.0);
			AccAmbientLoc.SpringTo(AmbientLocTarget, 50.0, 0.5, DeltaTime);
		}
		else
		{
			AccAmbientLoc.AccelerateTo(FVector(), 0.1, DeltaTime);
			AccAmbientRot.AccelerateTo(FQuat(), 1.0, DeltaTime);
		}

		SlidingDisc.Pivot.SetRelativeRotation(AccAmbientRot.Value);
		SlidingDisc.Pivot.SetRelativeLocation(AccAmbientLoc.Value);
	}
}

