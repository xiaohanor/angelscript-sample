class UTeenDragonConstrainToScreenCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	UTeenDragonConstrainToScreenComponent ConstrainComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ConstrainComp = UTeenDragonConstrainToScreenComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!ConstrainComp.bConstrainToScreen)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const	
	{
		if(!ConstrainComp.bConstrainToScreen)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.OverrideResolver(UTeenDragonConstrainToScreenSteppingMovementResolver, this, EInstigatePriority::Low);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ClearResolverOverride(UTeenDragonConstrainToScreenSteppingMovementResolver, this);
	}
};