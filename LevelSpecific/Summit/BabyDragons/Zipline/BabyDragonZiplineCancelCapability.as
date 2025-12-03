
class UBabyDragonZiplineCancelCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(n"BabyDragon");
	default CapabilityTags.Add(n"Zipline");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 8;

	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailBabyDragonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DragonComp.ZiplineState != ETailBabyDragonZiplineState::Follow)
			return false;
		if (!WasActionStarted(ActionNames::Cancel) && !WasActionStarted(ActionNames::MovementJump))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.ZiplineState = ETailBabyDragonZiplineState::None;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
}