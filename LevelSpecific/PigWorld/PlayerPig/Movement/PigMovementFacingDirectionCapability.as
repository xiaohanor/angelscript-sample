class UPigMovementFacingDirectionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder + 50;

	default DebugCategory = PigTags::Pig;

	UPlayerMovementComponent MovementComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovementComponent = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.SetMovementFacingDirection(Owner.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector MovementDirection = MovementComponent.GetMovementInput();
		if (!MovementDirection.IsNearlyZero())
			Player.SetMovementFacingDirection(MovementDirection.GetSafeNormal());
	}
}