class UDarkPortalPlayerRecallCapability : UHazePlayerCapability
{
	// Might want gameplayaction, but then we need a separate capability for passive recalls
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalRecall);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 89;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UDarkPortalUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerHealthComponent HealthComp;

	float CoolDownTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkPortalUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		HealthComp = UPlayerHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Portal.IsSettled() && !Portal.IsLaunching() && (UserComp.Companion.CompanionComp.State != EDarkPortalCompanionState::InvestigatingAttached))
			return false;

		// Recall if player dies
		if (HealthComp.bIsDead)
			return true;

		if (IsActioning(ActionNames::SecondaryLevelAbility))
			return false;
		
		// No flickering activation from mashing cancel button etc
		if (Time::GameTimeSeconds < CoolDownTime)
			return false; 

		// Recall when the cancel button is pressed
		if (WasActionStarted(ActionNames::Cancel))
			return true; 

		// Recall if the player is too far away from the portal
		if (Portal.GetDistanceTo(Player) > UserComp.Companion.Settings.AutoRecallRange)
			return true; 

		// Recall if companion wants to go investigating
		if ((Portal.State == EDarkPortalState::Settle) && UserComp.Companion.CompanionComp.InvestigationDestination.Get().bOverridePlayerControl)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Portal.Recall();
		UserComp.bWantsRecall = true;
		UDarkPortalPlayerEventHandler::Trigger_DarkPortalRecall(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.bWantsRecall = false;
		CoolDownTime = Time::GameTimeSeconds + 0.2;
	}

	ADarkPortalActor GetPortal() const property
	{
		return UserComp.Portal;
	}
}