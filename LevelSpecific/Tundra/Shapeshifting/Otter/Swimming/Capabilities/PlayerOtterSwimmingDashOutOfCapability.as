class UPlayerOtterSwimmingDashOutOfCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swimming);
	default CapabilityTags.Add(PlayerSwimmingTags::SwimmingDash);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 35;

	UTundraPlayerOtterSwimmingComponent SwimmingComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwimmingComp = UTundraPlayerOtterSwimmingComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SwimmingComp.ChangedStateThisFrameOrLast())
			return false;

		if(SwimmingComp.PreviousState != ETundraPlayerOtterSwimmingState::UnderwaterDash)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration > 1)
			return true;

		if(Player.ActorVerticalVelocity.DotProduct(-Player.MovementWorldUp) >= 0)
			return true;

		if(!MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Player.Mesh.CanRequestLocomotion())
			Player.Mesh.RequestLocomotion(n"Jump", this);
	}
}