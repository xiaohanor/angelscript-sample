struct FGravityBikeSplineEnemyMissileDroppedNoTargetDeactivateParams
{
	bool bExplode = false;
};

class UGravityBikeSplineEnemyMissileDroppedNoTargetCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 70;

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
		if(Missile.GrabTargetComp.IsGrabbed())
			return false;

		if(Missile.GetState() != EGravityBikeSplineEnemyMissileState::Dropped)
			return false;

		if(GrabTargetComp.HasThrowTarget())
			return false;

		if(Missile.MovementData.HasAppliedMovementThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeSplineEnemyMissileDroppedNoTargetDeactivateParams& Params) const
	{
		if(Missile.GrabTargetComp.IsGrabbed())
			return true;

		if(Missile.GetState() != EGravityBikeSplineEnemyMissileState::Dropped)
			return true;

		if(GrabTargetComp.HasThrowTarget())
			return true;

		if(Missile.MovementData.HasAppliedMovementThisFrame())
			return true;

		if(ActiveDuration > Missile.DroppedNoTargetLifeTime)
		{
			Params.bExplode = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Missile.BP_ActivateVFX();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineEnemyMissileDroppedNoTargetDeactivateParams Params)
	{
		if(Params.bExplode && IsValid(Missile))
		{
			Missile.Explode(nullptr, Owner.ActorLocation, -Owner.ActorVelocity.GetSafeNormal());
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Missile.MovementData.AccMoveSpeed.AccelerateTo(Missile.MissileSettings.DroppedMoveSpeed, 1, DeltaTime);
		const FVector WorldVelocity = Missile.ActorForwardVector * Missile.MovementData.AccMoveSpeed.Value;

		Missile.MovementData.AddWorldVelocity(WorldVelocity, DeltaTime);
		Missile.MovementData.ApplyOnActor(Missile, DeltaTime);

		if(HasControl())
			Missile.TraceForward(Missile.MovementData.PreviousLocation, Missile.ActorLocation);
	}
};