class ULightBirdPlayerLanternCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(LightBird::Tags::LightBird);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ULightBirdUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = ULightBirdUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.State != ELightBirdState::Hover)
			return false;
		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return false;
		if (IsActioning(ActionNames::PrimaryLevelAbility))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return true;
		if (IsActioning(ActionNames::PrimaryLevelAbility))
			return true;
		if (UserComp.State != ELightBirdState::Lantern)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	 	UserComp.Lantern();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (UserComp.State == ELightBirdState::Lantern)
			UserComp.Hover();
	}
}