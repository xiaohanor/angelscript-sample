struct FGravityBikeSplineEnemyMissileFlyStraightDeactivateParams
{
	bool bTransitionToTurnAround = false;
}

class UGravityBikeSplineEnemyMissileFlyStraightCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

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

		if(Missile.GetState() != EGravityBikeSplineEnemyMissileState::FlyStraight)
			return false;

		if(Missile.MovementData.HasAppliedMovementThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeSplineEnemyMissileFlyStraightDeactivateParams& Params) const
	{
		if(GrabTargetComp.IsGrabbed())
			return true;

		if(Missile.GetState() != EGravityBikeSplineEnemyMissileState::FlyStraight)
			return true;

		if(ActiveDuration > Missile.MissileSettings.FlyStraightTime)
		{
			Params.bTransitionToTurnAround = true;
			return true;
		}

		if(Missile.MovementData.HasAppliedMovementThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineEnemyMissileFlyStraightDeactivateParams Params)
	{
		if(Params.bTransitionToTurnAround)
		{
			Missile.ChangeState(EGravityBikeSplineEnemyMissileState::TurnAround);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Missile.MovementData.Prepare(Missile.ActorLocation, Missile.ActorQuat, this);

		Missile.MovementData.TickFlyStraight(Missile.GetSplineTransform().Location, Missile.MissileSettings.FlyStraightMoveSpeed, DeltaTime);

		Missile.MovementData.ApplyOnActor(Missile, DeltaTime);

		if(HasControl())
			Missile.TraceForward(Missile.MovementData.PreviousLocation, Missile.ActorLocation);
	}
};