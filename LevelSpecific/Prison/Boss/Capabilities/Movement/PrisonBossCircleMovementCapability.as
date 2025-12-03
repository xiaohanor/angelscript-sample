class UPrisonBossCircleMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	APrisonBoss Boss;
	
	FSplinePosition SplinePosition;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<APrisonBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// if (!Boss.bFlying)
			// return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if (!Boss.bFlying)
			// return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplinePosition = FSplinePosition(Boss.CircleSplineAirInner.Spline, Boss.CircleSplineAirInner.Spline.GetClosestSplineDistanceToWorldLocation(Boss.ActorLocation), true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SplinePosition.Move(PrisonBoss::CircleMoveSpeed * DeltaTime);

		FVector Loc = Math::VInterpTo(Boss.ActorLocation, SplinePosition.WorldLocation, DeltaTime, 3.0);

		Boss.SetActorLocation(Loc);

		FRotator Rot = SplinePosition.WorldRotation.Rotator();
		Rot.Yaw -= 90.0;
		Boss.SetActorRotation(Rot);
	}
}