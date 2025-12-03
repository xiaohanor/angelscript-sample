class UPinballBossFollowingStateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::Gameplay;

	APinballBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<APinballBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.BossState != EPinballBossState::Following)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.BossState != EPinballBossState::Following)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.SetBossState(EPinballBossState::Following);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TargetSplineDistance = Boss.ActiveSpline.Spline.GetClosestSplineDistanceToWorldLocation(Drone::GetMagnetDronePlayer().GetActorLocation());
		TargetSplineDistance += Boss.SplineOffset;
		const FVector TargetLocation = Boss.ActiveSpline.Spline.GetWorldLocationAtSplineDistance(TargetSplineDistance);
		const FVector Location = Math::VInterpTo(Boss.ActorLocation, TargetLocation, DeltaTime, 1.25);
		Boss.SetActorLocation(Location);

		const FVector LookAtDirection = Drone::GetMagnetDronePlayer().GetActorLocation()- Boss.ActorLocation;
		FRotator LookAtRotation = FRotator::MakeFromX(LookAtDirection);
		LookAtRotation.Pitch = Math::ClampAngle(LookAtRotation.Pitch, -25, 25);

		const FRotator Rotation = Math::RInterpTo(Boss.ActorRotation, LookAtRotation, DeltaTime, 1);
		Boss.SetActorRotation(Rotation);

		if(!Boss.bBallRotationControlledFromBP)
		{
			const FRotator BallRotation = Math::RInterpTo(LookAtRotation, Boss.BallLookAtComp.WorldRotation, DeltaTime, 10);
			Boss.BallLookAtComp.SetWorldRotation(BallRotation);
		}
	}
};