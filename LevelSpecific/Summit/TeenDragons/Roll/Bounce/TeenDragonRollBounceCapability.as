class UTeenDragonRollBounceCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	UTeenDragonRollBounceComponent BounceComp;
	UPlayerTailTeenDragonComponent UserComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BounceComp = UTeenDragonRollBounceComponent::Get(Player);
		UserComp = UPlayerTailTeenDragonComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BounceComp.HasResolverBouncedThisFrame())
			return false;

		if(!MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BounceComp.bHasBouncedSinceLanding = true;
		Player.PlayForceFeedback(UserComp.JumpRumble, false, false, this, 0.8);
		// Effect handler event here
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BounceComp.bHasBouncedSinceLanding = false;
	}
};