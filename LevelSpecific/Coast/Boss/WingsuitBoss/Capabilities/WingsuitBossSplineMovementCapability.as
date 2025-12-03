
class UWingsuitBossSplineMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 50;
	default CapabilityTags.Add(CapabilityTags::Movement);	

	UWingsuitBossSettings Settings;
	AWingsuitBoss Boss;
	float WobbleTimer = 0.0;

	FVector TargetOffset;
	FSplinePosition SplinePos;

	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedVector AccOffset;
	FHazeAcceleratedFloat AccSpeed;

	UHazeCrumbSyncedVectorComponent CrumbSyncedLocation;
	UHazeCrumbSyncedRotatorComponent CrumbSyncedRotation;

	uint LastTeleportFrame = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<AWingsuitBoss>(Owner);
		Settings = UWingsuitBossSettings::GetSettings(Owner);
		CrumbSyncedLocation = UHazeCrumbSyncedVectorComponent::Get(Owner);
		CrumbSyncedRotation = UHazeCrumbSyncedRotatorComponent::Get(Owner);
		UTeleportResponseComponent::Get(Owner).OnTeleported.AddUFunction(this, n"OnTeleported");
	}

	UFUNCTION()
	private void OnTeleported()
	{
		LastTeleportFrame = Time::FrameNumber;
		if (!IsActive())
			return;
		SplinePos = Boss.FollowingSpline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
		AccOffset.SnapTo(SplinePos.WorldTransform.InverseTransformPosition(Owner.ActorLocation));
		AccSpeed.SnapTo(Boss.FollowSplineSpeed);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.FollowingSpline == nullptr)
			return false;
		if (Boss.bHasMovedThisFrame)
			return false;		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Boss.FollowingSpline == nullptr)
			return true;
		if (Boss.bHasMovedThisFrame)
			return true;		
		if (Boss.FollowingSpline != SplinePos.CurrentSpline)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(!HasControl())
			return;

		SplinePos = Boss.FollowingSpline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
		AccOffset.SnapTo(SplinePos.WorldTransform.InverseTransformPosition(Owner.ActorLocation));
		AccRotation.SnapTo(Owner.ActorRotation);
		AccSpeed.SnapTo(SplinePos.WorldForwardVector.DotProduct(Boss.ActorVelocity));
		if (Time::FrameNumber < LastTeleportFrame + 1)
			AccSpeed.SnapTo(Boss.FollowSplineSpeed);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.RepositionTimer = Settings.InitialRepositionDelay;
		if (Boss.FollowingSpline == SplinePos.CurrentSpline)
			Boss.FollowingSpline = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			AccSpeed.AccelerateTo(Boss.FollowSplineSpeed, 10.0, DeltaTime);
			AccOffset.AccelerateToWithStop(FVector::ZeroVector, 10.0, DeltaTime, 10.0);
			SplinePos.Move(AccSpeed.Value * DeltaTime);

			FVector TargetLocation = SplinePos.WorldTransform.TransformPosition(AccOffset.Value);

			// Wobble
			WobbleTimer += 2.0 * DeltaTime;
			TargetLocation.Z += 200.0 * Math::Sin(WobbleTimer);
			TargetLocation.Y += 200.0 * Math::Sin(WobbleTimer * 0.79);

			FRotator TargetRotation;
			if(!Boss.OverrideTargetRotation.IsDefaultValue())
				TargetRotation = Boss.OverrideTargetRotation.Get();
			else if (Boss.bFollowSplineLookAtTargets)
				TargetRotation = GetRotationTowardsTargets();
			else
				TargetRotation = SplinePos.WorldRotation.Rotator();

			AccRotation.AccelerateTo(TargetRotation, 3.0, DeltaTime);
			CrumbSyncedLocation.Value = TargetLocation;
			CrumbSyncedRotation.Value = AccRotation.Value;
		}		
		
		// Set position (this will be replicated values on remote)
		Owner.SetActorLocationAndRotation(CrumbSyncedLocation.Value, CrumbSyncedRotation.Value);
		Boss.bHasMovedThisFrame = true;

		// Stop following spline when we reach it's end
		if (HasControl() && SplinePos.CurrentSplineDistance > SplinePos.CurrentSpline.SplineLength - 100.0)
			Boss.FollowingSpline = nullptr; 
	}

	FRotator GetRotationTowardsTargets()
	{
		FVector FocusOffset = FVector::ZeroVector;
		int NumValidTargets = 0;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.IsPlayerDead())
				continue;
			NumValidTargets++;
			FocusOffset += Player.ActorCenterLocation - Owner.ActorLocation;
		}
		if (NumValidTargets == 0)
			return Owner.ActorRotation;
		FocusOffset /= float(NumValidTargets);
		return FocusOffset.Rotation();
	}
};
