struct FGravityBikeSplineEnemyMissileHomingDeactivateParams
{
	bool bMissed = false;
};

class UGravityBikeSplineEnemyMissileHomingCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 80;

	AGravityBikeSplineEnemyMissile Missile;
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Missile = Cast<AGravityBikeSplineEnemyMissile>(Owner);
		GrabTargetComp = UGravityBikeWhipGrabTargetComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GrabTargetComp.IsGrabbed())
			return false;

		if(Missile.GetState() != EGravityBikeSplineEnemyMissileState::Homing)
			return false;

		if(Missile.MovementData.HasAppliedMovementThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeSplineEnemyMissileHomingDeactivateParams& Params) const
	{
		if(GrabTargetComp.IsGrabbed())
			return true;

		if(Missile.GetState() != EGravityBikeSplineEnemyMissileState::Homing)
			return true;

		if(Missile.MovementData.HasAppliedMovementThisFrame())
			return true;

		const FVector TargetLocation = Missile.GetPlayerLocation();
		const FVector ToTarget = (TargetLocation - Missile.ActorLocation).GetSafeNormal();
		const float Dot = Missile.ActorForwardVector.DotProduct(ToTarget);
		if(Dot < 0.1)
		{
			// We missed :c
			Params.bMissed = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineEnemyMissileHomingDeactivateParams Params)
	{
		if(Params.bMissed)
		{
			Missile.ChangeState(EGravityBikeSplineEnemyMissileState::Dropped);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Missile.MovementData.Prepare(Missile.ActorLocation, Missile.ActorQuat, this);

		Missile.MovementData.TickHoming(
			Missile.GetSplineTransform().Location,
			Missile.MissileSettings.HomingMoveSpeed,
			Missile.MissileSettings.HomingTurnSpeed,
			DeltaTime,
			Missile.GetPlayerLocation()
		);

		Missile.MovementData.ApplyOnActor(Missile, DeltaTime);

		if(HasControl())
			Missile.TraceForward(Missile.MovementData.PreviousLocation, Missile.ActorLocation);
	}
};