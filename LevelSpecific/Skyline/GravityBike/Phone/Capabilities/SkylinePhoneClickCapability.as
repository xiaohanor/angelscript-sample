class USkylinePhoneClickCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	USkylinePhoneUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USkylinePhoneUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.Phone == nullptr)
			return false;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility) && !WasActionStarted(ActionNames::MovementJump))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (UserComp.Phone == nullptr)
			return true;

		if (!IsActioning(ActionNames::PrimaryLevelAbility) && !IsActioning(ActionNames::MovementJump))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.bClickPressed = true;
		UserComp.Phone.Click();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.bClickPressed = false;
		UserComp.Phone.Release();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};