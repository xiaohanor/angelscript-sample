class UDarkParasiteGrabCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(DarkParasite::Tags::DarkParasite);
	default CapabilityTags.Add(DarkParasite::Tags::DarkParasiteGrab);
	
	default DebugCategory = DarkParasite::Tags::DarkParasite;

	default TickGroupOrder = 151;

	UDarkParasiteUserComponent UserComp;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkParasiteUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.IsAiming())
			return false;

		if (!UserComp.FocusedData.IsValid())
			return false;

		if (!UserComp.AttachedData.IsValid())
			return false;

		if (UserComp.FocusedData.Actor == UserComp.AttachedData.Actor)
			return false;

		if (!DarkParasite::bAltControlScheme)
		{
			if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
				return false;
		}
		else
		{
			if (!WasActionStarted(ActionNames::SecondaryLevelAbility))
				return false;
		}
		
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
		// Release current grabbed component
		if (UserComp.GrabbedData.IsValid())
		{
			DarkParasite::TriggerHierarchyRelease(Player,
				UserComp.AttachedData,
				UserComp.GrabbedData);

			UserComp.GrabbedData = FDarkParasiteTargetData();
		}

		UserComp.GrabbedData = UserComp.FocusedData;
		UserComp.GrabbedData.Timestamp = Time::GameTimeSeconds;
		UserComp.LastGrabFrame = Time::FrameNumber;

		// Don't trigger grab until DarkParasite::GrabDelay
		// DarkParasite::TriggerHierarchyGrab(Player,
		// 	UserComp.AttachedData,
		// 	UserComp.GrabbedData);
	}
}