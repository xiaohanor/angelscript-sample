class UDarkParasiteAttachCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(DarkParasite::Tags::DarkParasite);
	default CapabilityTags.Add(DarkParasite::Tags::DarkParasiteAttach);
	
	default DebugCategory = DarkParasite::Tags::DarkParasite;
	
	default TickGroupOrder = 131;

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

		// Don't attach to targetable-less components
		auto FocusedTargetable = Cast<UTargetableComponent>(UserComp.FocusedData.TargetComponent);
		if (FocusedTargetable == nullptr)
			return false;

		if (UserComp.AttachedData.IsValid())
			return false;

		if (!DarkParasite::bAltControlScheme)
		{
			if (UserComp.AttachedData.IsValid())
			{
				if (UserComp.FocusedData.Actor != UserComp.AttachedData.Actor)
					return false;
			}

			if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
				return false;
		}
		else
		{
			if (!WasActionStopped(ActionNames::SecondaryLevelAbility))
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
		// If we have a previously grabbed component, release it
		if (UserComp.GrabbedData.IsValid())
		{
			DarkParasite::TriggerHierarchyRelease(Player,
				UserComp.AttachedData,
				UserComp.GrabbedData);

			UserComp.GrabbedData = FDarkParasiteTargetData();
		}

		// Detach if we're focusing the attached component
		if (UserComp.AttachedData.IsValid())
		{
			DarkParasite::TriggerHierarchyDetach(Player,
				UserComp.AttachedData);

			UserComp.AttachedData = FDarkParasiteTargetData();
		}

		UserComp.AttachedData = UserComp.FocusedData;
		UserComp.AttachedData.Timestamp = Time::GameTimeSeconds;
		UserComp.LastAttachFrame = Time::FrameNumber;

		DarkParasite::TriggerHierarchyAttach(Player,
			UserComp.AttachedData);
	}
}