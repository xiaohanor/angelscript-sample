class UAdultDragonLandingSiteHornCapability : UHazePlayerCapability
{
	UPlayerTargetablesComponent TargetablesComp;
	UAdultDragonLandingSiteComponent LandingSiteComp;
	UAdultDragonLandingSiteSettings Settings;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	float TimeOfLastInteract = -100.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		LandingSiteComp = UAdultDragonLandingSiteComponent::Get(Player);
		Settings = UAdultDragonLandingSiteSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive() && !IsBlocked() && LandingSiteComp.bAtLandingSite)
		{
			TargetablesComp.ShowWidgetsForTargetables(UAdultDragonLandingSiteHornTargetableComponent);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FAdultDragonLandingSiteHornCapabilityActivatedParams& Params) const
	{
		if(!LandingSiteComp.bAtLandingSite)
			return false;

		if(!WasActionStarted(ActionNames::Interaction))
			return false;

		auto PrimaryTarget = TargetablesComp.GetPrimaryTarget(UAdultDragonLandingSiteHornTargetableComponent);

		if(PrimaryTarget == nullptr)
			return false;

		auto LandingSite = Cast<AAdultDragonLandingSite>(PrimaryTarget.Owner);

		Params.HornTargetable = PrimaryTarget;
		Params.LandingSite = LandingSite;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!LandingSiteComp.bAtLandingSite)
			return true;

		if(ActiveDuration > Settings.HornInteractionCooldown)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FAdultDragonLandingSiteHornCapabilityActivatedParams Params)
	{
		FOnLandingSiteBlowParams EffectParams;
		EffectParams.BlowPoint = LandingSiteComp.CurrentLandingSite.BlowEffectRoot;
		UAdultDragonLandingSiteEffectHandler::Trigger_OnHornBlow(LandingSiteComp.CurrentLandingSite, EffectParams);

		TimeOfLastInteract = Time::GetGameTimeSeconds();
		Params.LandingSite.TimeUntilNextAvailableBlow = Time::GetGameTimeSeconds() + Settings.HornInteractionCooldown;
		Params.LandingSite.OnBlowHorn.Broadcast();
		Player.SetTutorialPromptState(LandingSiteComp, ETutorialPromptState::Unavailable);
		LandingSiteComp.bBlowingHorn = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.SetTutorialPromptState(LandingSiteComp, ETutorialPromptState::Normal);
		LandingSiteComp.bBlowingHorn = false;
	}
}

struct FAdultDragonLandingSiteHornCapabilityActivatedParams
{
	UAdultDragonLandingSiteHornTargetableComponent HornTargetable;
	AAdultDragonLandingSite LandingSite;
}