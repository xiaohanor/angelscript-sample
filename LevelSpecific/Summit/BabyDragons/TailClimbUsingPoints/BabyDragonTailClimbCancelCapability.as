class UBabyDragonTailClimbCancelCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(n"BabyDragon");
	default CapabilityTags.Add(n"TailClimb");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 7;
	default TickGroupSubPlacement = 8;

	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UHazeOffsetComponent OffsetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailBabyDragonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		OffsetComp = Player.GetMeshOffsetComponent();
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DragonComp.ClimbState != ETailBabyDragonClimbState::Hang)
			return false;
		if (!WasActionStarted(ActionNames::Cancel))
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
		DragonComp.ClimbState = ETailBabyDragonClimbState::None;
		OffsetComp.FreezeRotationAndLerpBackToParent(this, 0.2);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
}