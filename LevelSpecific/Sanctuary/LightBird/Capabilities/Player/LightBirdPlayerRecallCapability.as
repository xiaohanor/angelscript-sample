class ULightBirdPlayerRecallCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default CapabilityTags.Add(LightBird::Tags::LightBirdRecall);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 89;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ULightBirdUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;

	float CoolDownTime = 0.0;

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
		if ((UserComp.State != ELightBirdState::Attached) && (UserComp.Companion.CompanionComp.State != ELightBirdCompanionState::InvestigatingAttached))
			return false;

		// Recall if player dies
		if (Player.IsPlayerDead())
			return true;

		if (IsActioning(ActionNames::SecondaryLevelAbility))
			return false;
		
		if (Time::GameTimeSeconds < CoolDownTime)
			return false; // Don't want flickering activation from mashing cancel button etc

		// Recall when the cancel button is pressed
		if (WasActionStarted(ActionNames::Cancel))
			return true;
		
		// Recall if the player is too far away from the bird, but not while in use
		if (!UserComp.bIsIlluminating && (UserComp.GetLightBirdLocation().Distance(Player.ActorLocation) > UserComp.Companion.Settings.AutoRecallRange))
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
		UserComp.Hover();
		UserComp.bWantsRecall = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.bWantsRecall = false;
		CoolDownTime = Time::GameTimeSeconds + 0.2;
	}
}