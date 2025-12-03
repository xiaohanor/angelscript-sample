
class UPlayerWallRunGroundedResetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	// default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunGroundedReset);
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComp;
	UPlayerWallRunComponent WallRunComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		WallRunComp = UPlayerWallRunComponent::GetOrCreate(Player);
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
		WallRunComp.bWallRunAvailableUntilGrounded = true;
		WallRunComp.bHasWallRunnedSinceLastGrounded = false;
	}
}