class UDarkPortalPlayerGrabCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalGrab);

	default TickGroup = EHazeTickGroup::ActionMovement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UDarkPortalUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;

	float LastActivationTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkPortalUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Portal.IsSettled())
			return false;

		float TimeSinceActivation = Time::GetRealTimeSince(LastActivationTime);
		if (LastActivationTime != 0.0 && TimeSinceActivation < 0.33)
			return false;

		if (TargetablesComp.TargetingMode.Get() != EPlayerTargetingMode::SideScroller)
		{
			if (AimComp.IsAiming(UserComp))
				return false;
		}

		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Portal.IsSettled())
			return true;
		
		if (TargetablesComp.TargetingMode.Get() != EPlayerTargetingMode::SideScroller)
		{
			if (AimComp.IsAiming(UserComp))
				return true;
		}

		if (Portal.ReleaseRequestTimestamp > 0.0)
		{
			float TimeSinceReleaseRequest = Time::GetGameTimeSince(Portal.ReleaseRequestTimestamp);
			if (TimeSinceReleaseRequest < ActiveDuration)
				return true;
		}

		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastActivationTime = Time::RealTimeSeconds;

		Portal.ReleaseRequestTimestamp = -1.0;
		Portal.bPlayerWantsGrab = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (IsValid(Portal))
			Portal.bPlayerWantsGrab = false;

		Player.ConsumeButtonInputsRelatedTo(ActionNames::SecondaryLevelAbility);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Portal.LastGrabTime = Time::GameTimeSeconds;
	}

	ADarkPortalActor GetPortal() const property
	{
		return UserComp.Portal;
	}
}