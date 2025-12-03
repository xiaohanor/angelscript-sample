
class UPlayerMovementDirectionFacingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
		
	default CapabilityTags.Add(n"MovementFacing");

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder + 50;

	// Internal Variables
	UPlayerMovementComponent MoveComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComponent = UPlayerMovementComponent::Get(Player);
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
	void OnDeactivated()
	{
	
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector MovementDirection = MoveComponent.GetMovementInput();
		if(!MovementDirection.IsNearlyZero())
		{
			Player.SetMovementFacingDirection(MovementDirection.GetSafeNormal());
		}
	}
};
