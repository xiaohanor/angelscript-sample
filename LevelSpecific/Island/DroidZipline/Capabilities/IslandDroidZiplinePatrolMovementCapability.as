class UIslandDroidZiplinePatrolMovementCapability : UIslandDroidZiplineBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::Movement;
	//default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UIslandDroidZiplineSettings Settings;

	float CurrentSplineDistance = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		Settings = UIslandDroidZiplineSettings::GetSettings(Droid);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Droid.CurrentDroidState != EIslandDroidZiplineState::Patrolling)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FIslandDroidZiplinePatrolMovementDeactivatedParams& Params) const
	{
		if(Droid.CurrentDroidState != EIslandDroidZiplineState::Patrolling)
			return true;

		if(CurrentSplineDistance >= Droid.PatrolSpline.Spline.SplineLength)
		{
			Params.bDespawn = true;
			return true;
		}

		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentSplineDistance = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FIslandDroidZiplinePatrolMovementDeactivatedParams Params)
	{
		if(Params.bDespawn)
			Droid.DespawnDroid();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CurrentSplineDistance += Settings.PatrolSpeed * DeltaTime;
		
		FTransform TargetTransform = Droid.PatrolSpline.Spline.GetWorldTransformAtSplineDistance(CurrentSplineDistance);
		Droid.SetActorVelocity((TargetTransform.Location - Droid.ActorLocation) / DeltaTime);
		Droid.ActorLocation = TargetTransform.Location;
		Droid.ActorRotation = Math::RInterpShortestPathTo(Droid.ActorRotation, TargetTransform.Rotation.Rotator(), DeltaTime, Settings.SplineRotationInterpSpeed);
	}
}

struct FIslandDroidZiplinePatrolMovementDeactivatedParams
{
	bool bDespawn = false;
}
