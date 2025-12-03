class UDarkParasiteGrabDelayCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(DarkParasite::Tags::DarkParasite);
	default CapabilityTags.Add(DarkParasite::Tags::DarkParasiteGrab);
	
	default DebugCategory = DarkParasite::Tags::DarkParasite;

	default TickGroupOrder = 152;

	UDarkParasiteUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkParasiteUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.GrabbedData.IsValid())
			return false;

		// Don't activate if we've already exited delay
		if (Time::GetGameTimeSince(UserComp.GrabbedData.Timestamp) >= DarkParasite::GrabDelay)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.GrabbedData.IsValid())
			return true;

		if (Time::GetGameTimeSince(UserComp.GrabbedData.Timestamp) >= DarkParasite::GrabDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (UserComp.GrabbedData.IsValid())
		{
			DarkParasite::TriggerHierarchyGrab(Player,
				UserComp.AttachedData,
				UserComp.GrabbedData);
		}
	}
}