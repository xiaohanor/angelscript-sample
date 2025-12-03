class USplitTraversalPushablePlatformCapability : UInteractionCapability
{
	ASplitTraversalPushableActor Pushable;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		Pushable = Cast<ASplitTraversalPushableActor>(ActiveInteraction.Owner);
		
		if (Player.IsMio())
		{
			FTutorialPrompt Prompt;
			Prompt.DisplayType = ETutorialPromptDisplay::LeftStick_UpDown;
			Player.ShowTutorialPrompt(Prompt, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		if (Player.IsMio())
		{
			Player.RemoveTutorialPromptByInstigator(this);
			Pushable.PlatformTargetPosition = 0.0;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.IsMio())
		{
			float Input = GetAttributeFloat(AttributeNames::LeftStickRawY);
			if (Input < 0.1)
				Pushable.PlatformTargetPosition = 0.0;
			else
				Pushable.PlatformTargetPosition = 1.0;
		}
	}
};