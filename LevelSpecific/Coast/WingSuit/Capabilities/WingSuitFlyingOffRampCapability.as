class UWingSuitFlyingOffRampCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::InfluenceMovement;

	UWingSuitPlayerComponent WingSuitComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WingSuitComp.AnimData.bIsFlyingOffRamp)
			return false;
		
		if(WingSuitComp.bWingsuitActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WingSuitComp.AnimData.bIsFlyingOffRamp)
			return true;

		if(WingSuitComp.bWingsuitActive)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(n"MovementFacing", this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);
		Player.SetMovementFacingDirection(Owner.ActorRotation);
		//Print(f"{Player.ActorVelocity=}");
		// This velocity is determined from the print above!
		Player.SetActorVelocity(FVector(4800.0, 0.0, 2200.0));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"MovementFacing", this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.MeshOffsetComponent.WorldRotation = Math::RInterpShortestPathTo(Player.MeshOffsetComponent.WorldRotation, FRotator::ZeroRotator, DeltaTime, 3.0);
		// This happens to be the correct facing direction over the ramp and it is unlikely to change so easiest to just hardcode it.
		Player.SetMovementFacingDirection(FVector::ForwardVector);

		if(Player.Mesh.CanRequestLocomotion())
		{
			Player.Mesh.RequestLocomotion(n"WingSuit", this);
		}
	}
}