class USkylinePhoneCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;
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
		if(!UserComp.bUsePhoneView)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!UserComp.bUsePhoneView)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.SetupPhone();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.RemovePhone();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("Phone Ready!", 0.0, FLinearColor::Green);
	}
};