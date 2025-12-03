struct FGravityBikeSplineEnemyMissileDroppedActivateParams
{
	UGravityBikeWhipThrowTargetComponent ThrowTarget;
}

class UGravityBikeSplineEnemyMissileDroppedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 60;

	AGravityBikeSplineEnemyMissile Missile;
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;

	UGravityBikeWhipThrowTargetComponent ThrowTargetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Missile = Cast<AGravityBikeSplineEnemyMissile>(Owner);
		GrabTargetComp = UGravityBikeWhipGrabTargetComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeSplineEnemyMissileDroppedActivateParams& Params) const
	{
		if(Missile.GrabTargetComp.IsGrabbed())
			return false;

		if(Missile.GetState() != EGravityBikeSplineEnemyMissileState::Dropped)
			return false;

		if(!GrabTargetComp.HasThrowTarget())
			return false;

		if(Missile.MovementData.HasAppliedMovementThisFrame())
			return false;

		Params.ThrowTarget = GrabTargetComp.GetThrowTarget();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Missile.GrabTargetComp.IsGrabbed())
			return true;

		if(Missile.GetState() != EGravityBikeSplineEnemyMissileState::Dropped)
			return true;

		if(!GrabTargetComp.HasThrowTarget())
			return true;

		if(Missile.MovementData.HasAppliedMovementThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeSplineEnemyMissileDroppedActivateParams Params)
	{
		ThrowTargetComp = Params.ThrowTarget;

		Missile.BP_ActivateVFX();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ThrowTargetComp = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!GrabTargetComp.HasThrowTarget())
			return;
		
		Missile.MovementData.Prepare(Missile.ActorLocation, Missile.ActorQuat, this);

		Missile.MovementData.AccMoveSpeed.AccelerateTo(Missile.MissileSettings.DroppedMoveSpeed, 1, DeltaTime);

		const FVector TargetLocation = Missile.GrabTargetComp.GetThrowTargetWorldLocation();
		Missile.MovementData.VInterpConstantTo(TargetLocation, DeltaTime, Missile.MovementData.AccMoveSpeed.Value);

		FQuat ToTarget = FQuat::MakeFromX(TargetLocation - Missile.MovementData.WorldLocation);
		FQuat NewRotation = Math::QInterpConstantTo(Missile.ActorQuat, ToTarget, DeltaTime, Missile.MissileSettings.DroppedTurnSpeed);
		Missile.MovementData.WorldRotation = NewRotation;

		Missile.MovementData.ApplyOnActor(Missile, DeltaTime);

		if(HasControl())
			Missile.TraceForward(Missile.MovementData.PreviousLocation, Missile.ActorLocation);
	}
};