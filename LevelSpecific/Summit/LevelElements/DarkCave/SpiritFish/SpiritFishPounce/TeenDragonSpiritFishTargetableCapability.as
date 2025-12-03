class UTeenDragonSpiritFishTargetableCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	UPlayerTargetablesComponent TargetablesComp;
	UTeenDragonSpiritFishPounceComponent UserComp;

	bool bWidgetShowing;

	ADarkCaveSpiritFish TargetedFish;

	bool bHavePounced;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		UserComp = UTeenDragonSpiritFishPounceComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.bIsPouncing)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (TargetablesComp.GetPrimaryTarget(UDarkCaveSpiritFishTargetableComponent) == nullptr)
			return false;

		if (!WasActionStarted(ActionNames::Interaction))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto Comp = TargetablesComp.GetPrimaryTarget(UDarkCaveSpiritFishTargetableComponent);
		if (Comp == nullptr)
			return;

		auto Fish = Cast<ADarkCaveSpiritFish>(Comp.Owner);
		FVector EndLoc = Fish.ActorLocation + Fish.ActorForwardVector * Fish.MoveSpeed * 0.5;
		UserComp.ActivatePounce(FTeenDragonSpiritFishPounceData(EndLoc, 500.0, Fish));

		bHavePounced = true;
		
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ADarkCaveSpiritFish CurrentFish = GetValidFish();

		// if (!bHavePounced)
		// {
			if (CanShowTutorialPrompt())
			{
				bWidgetShowing = true;

				if (TargetedFish != CurrentFish)
				{
					if (CurrentFish != nullptr)
					{
						Player.RemoveTutorialPromptByInstigator(this);
						TargetedFish = CurrentFish;

						FTutorialPrompt Prompt;
						Prompt.Action = ActionNames::Interaction;
						Prompt.DisplayType = ETutorialPromptDisplay::Action;
						Player.ShowTutorialPromptWorldSpace(Prompt, this, TargetedFish.MeshComp, FVector(0, 10, -5), 0.0);
					}
					else
					{
						Player.RemoveTutorialPromptByInstigator(this);
					}
				}
			}
			else if (!CanShowTutorialPrompt() && bWidgetShowing)
			{
				bWidgetShowing = false;
				Player.RemoveTutorialPromptByInstigator(this);
			}
		// }

		FTargetableOutlineSettings OutlineSettings;
		OutlineSettings.MaximumOutlinesVisible = 1;
		OutlineSettings.bAllowPrimaryTargetOutline = true;
		OutlineSettings.TargetableCategory = n"SpiritFish";
		TargetablesComp.ShowOutlinesForTargetables(OutlineSettings);
	}

	bool CanShowTutorialPrompt() const
	{
		return TargetablesComp.GetPrimaryTarget(UDarkCaveSpiritFishTargetableComponent) != nullptr;
	}

	ADarkCaveSpiritFish GetValidFish()
	{
		auto Comp = TargetablesComp.GetPrimaryTarget(UDarkCaveSpiritFishTargetableComponent);
		if (Comp == nullptr)
			return nullptr;

		auto Fish = Cast<ADarkCaveSpiritFish>(Comp.Owner);		

		return Fish;
	}
};