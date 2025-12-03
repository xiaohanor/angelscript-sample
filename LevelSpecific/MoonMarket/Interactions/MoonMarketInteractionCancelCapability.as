class UMoonMarketInteractionCancelCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"InteractionCancel");
	default CapabilityTags.Add(n"MoonMarketInteractionCancel");
	default BlockExclusionTags.Add(n"InteractionCancel");
	default BlockExclusionTags.Add(n"MoonMarketInteractionCancel");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UMoonMarketPlayerInteractionComponent InteractComp;

	bool bCanCancel = false;
	bool bShouldCancel = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		InteractComp = UMoonMarketPlayerInteractionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(InteractComp.CurrentInteractions.IsEmpty())
			return false;

		if(InteractComp.CurrentInteractions.Num() == 1 && !InteractComp.CurrentInteractions[0].bShowCancelPrompt)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(InteractComp.CurrentInteractions.IsEmpty())
			return true;

		if(InteractComp.CurrentInteractions.Num() == 1 && !InteractComp.CurrentInteractions[0].bShowCancelPrompt)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(InteractComp.CurrentInteractions.Last().bUseCustomCancelText)
			Player.ShowCancelPromptWithText(this, InteractComp.CurrentInteractions.Last().CustomCancelText);
		else
			Player.ShowCancelPrompt(this);

		bCanCancel = false;
		bShouldCancel = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveCancelPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(WasActionStarted(ActionNames::Cancel))
		{
			if(bCanCancel)
			{
				InteractComp.CrumbCancelLatestInteraction();
				Player.RemoveCancelPromptByInstigator(this);
				
				if(!InteractComp.CurrentInteractions.IsEmpty())
				{
					if(InteractComp.CurrentInteractions.Last().bUseCustomCancelText)
						Player.ShowCancelPromptWithText(this, InteractComp.CurrentInteractions.Last().CustomCancelText);
					else if(InteractComp.CurrentInteractions.Last().bShowCancelPrompt)
						Player.ShowCancelPrompt(this);
				}
			}
			else
			{
				bShouldCancel = true;
			}
		}

		if(!bCanCancel)
		{
			if(ActiveDuration >= 0.3)
			{
				bCanCancel = true;

				if(bShouldCancel)
				{
					InteractComp.CrumbCancelLatestInteraction();
					bShouldCancel = false;
				}
			}
		}
	}
};