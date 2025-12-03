
class UPlayerAirJumpGroundedResetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 99;

	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComp;
	UPlayerAirJumpComponent AirJumpComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		AirJumpComp = UPlayerAirJumpComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!MoveComp.IsOnWalkableGround())
			return false;		

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!MoveComp.IsOnWalkableGround())
			return true;
	
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		AirJumpComp.bCanAirJump = true;
		if (!MoveComp.HasUpwardsImpulse())
			AirJumpComp.bKeepLaunchVelocityDuringAirJumpUntilLanded = false;
	}
}