struct FGravityBikeSplineEnemyMissileTurnAroundActivateParams
{
	FVector TargetWorldDirection;
};

class UGravityBikeSplineEnemyMissileTurnAroundCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 90;

	AGravityBikeSplineEnemyMissile Missile;
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;

	FVector TargetWorldDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Missile = Cast<AGravityBikeSplineEnemyMissile>(Owner);
		GrabTargetComp = UGravityBikeWhipGrabTargetComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeSplineEnemyMissileTurnAroundActivateParams& Params) const
	{
		if(GrabTargetComp.IsGrabbed())
			return false;

		if(Missile.GetState() != EGravityBikeSplineEnemyMissileState::TurnAround)
			return false;

		if(Missile.MovementData.HasAppliedMovementThisFrame())
			return false;

		Params.TargetWorldDirection = (Missile.GetPlayerLocation() - Missile.ActorLocation).GetSafeNormal();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GrabTargetComp.IsGrabbed())
			return true;

		if(Missile.GetState() != EGravityBikeSplineEnemyMissileState::TurnAround)
			return true;

		if(Missile.MovementData.HasAppliedMovementThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeSplineEnemyMissileTurnAroundActivateParams Params)
	{
		TargetWorldDirection = Params.TargetWorldDirection;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Missile.MovementData.Prepare(Missile.ActorLocation, Missile.ActorQuat, this);

		bool bFinished = Missile.MovementData.TickTurnAround(Missile.GetSplineTransform().Location, Missile.MissileSettings.TurnAroundMoveSpeed, Missile.MissileSettings.TurnAroundTurnSpeed, DeltaTime, TargetWorldDirection);
		Missile.MovementData.ApplyOnActor(Missile, DeltaTime);

		// We have turned around enough
		if(bFinished)
			Missile.ChangeState(EGravityBikeSplineEnemyMissileState::Homing);

		if(HasControl())
			Missile.TraceForward(Missile.MovementData.PreviousLocation, Missile.ActorLocation);
	}
};