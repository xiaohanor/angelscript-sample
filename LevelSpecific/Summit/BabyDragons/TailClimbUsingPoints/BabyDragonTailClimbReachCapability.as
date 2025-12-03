class UBabyDragonTailClimbReachCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(n"BabyDragon");
	default CapabilityTags.Add(n"TailClimb");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 7;
	default TickGroupSubPlacement = 9;

	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerTargetablesComponent TargetablesComp;

	ABabyDragonTailClimbPoint TargetPoint;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		DragonComp = UPlayerTailBabyDragonComponent::Get(Player);
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBabyDragonTailClimbTransferParams& Params) const
	{
		if (DragonComp.ClimbState != ETailBabyDragonClimbState::Hang)
			return false;
		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FBabyDragonTailClimbTransferDeactivationParams& Params) const
	{
		if (DragonComp.ClimbState != ETailBabyDragonClimbState::Hang)
			return true;
		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBabyDragonTailClimbTransferParams Params)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FBabyDragonTailClimbTransferDeactivationParams Params)
	{
		DragonComp.AnimationState.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto PrimaryTarget = TargetablesComp.GetPrimaryTarget(UBabyDragonTailClimbTargetable);
		if (PrimaryTarget != nullptr)
		{
			auto Point = Cast<ABabyDragonTailClimbPoint>(PrimaryTarget.Owner);
			DragonComp.AnimationState.Apply(ETailBabyDragonAnimationState::ClimbReach, this);
		}
		else
		{
			DragonComp.AnimationState.Clear(this);
		}
	}
}
