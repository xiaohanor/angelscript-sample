class UPigLandingCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 80;

	default DebugCategory = PigTags::Pig;

	UPlayerMovementComponent MovementComponent;
	UPlayerPigComponent PigComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		PigComponent = UPlayerPigComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (!MovementComponent.IsOnAnyGround())
			return false;

		if (MovementComponent.HasUpwardsImpulse())
			return false;

		if (!MovementComponent.WasFalling() && !MovementComponent.WasInAir())
			return false;

		return true;
	}

	// Just tick for one frame
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"Landing", this);
	}
}