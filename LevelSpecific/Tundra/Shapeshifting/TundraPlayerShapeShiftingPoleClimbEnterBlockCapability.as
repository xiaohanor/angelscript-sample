
/**
 * The enter capability. Until we decide to only enter pole climb from not grounded,
 * this is required to no reenter when gliding down
 */
// class UTundraPlayerShapeShiftingPoleClimbEnterBlockCapability : UHazePlayerCapability
// {
// 	UHazeMovementComponent MoveComp;
	
// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		MoveComp = UHazeMovementComponent::Get(Player);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const
// 	{
// 		if(!MoveComp.IsOnAnyGround())
// 			return false;

// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		if(!MoveComp.IsOnAnyGround())
// 			return true;

// 		return false;
// 	}
	
// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated()
// 	{
// 		Player.BlockCapabilities(PlayerMovementTags::PoleClimb, this);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		Player.UnblockCapabilities(PlayerMovementTags::PoleClimb, this);
// 	}
// }