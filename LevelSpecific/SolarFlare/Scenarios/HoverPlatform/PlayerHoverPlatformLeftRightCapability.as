class UPlayerHoverPlatformLeftRightCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"PlayerHoverPlatformLeftRightCapability");
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	USolarFlareHoverPlatformComponent UserComp;
	ASolarFlareHoverPlatform Platform;

	float MoveSpeed = 500.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USolarFlareHoverPlatformComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.MovementMode != ESolarFlareHoverPlatformMovementMode::LeftRight)
			return false;

		if (!UserComp.bActivated)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (UserComp.MovementMode != ESolarFlareHoverPlatformMovementMode::LeftRight)
			return true;
		
		if (!UserComp.bActivated)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Platform = UserComp.Platform;

		FTutorialPrompt PromptRight;
		PromptRight.Action = ActionNames::PrimaryLevelAbility;
		PromptRight.DisplayType = ETutorialPromptDisplay::ActionHold;
		PromptRight.Text = NSLOCTEXT("HoverPlatformTutorial", "RightPrompt", "Activate Thruster");
		FTutorialPrompt PromptLeft;
		PromptLeft.Action = ActionNames::SecondaryLevelAbility;
		PromptLeft.DisplayType = ETutorialPromptDisplay::ActionHold;
		PromptLeft.Text = NSLOCTEXT("HoverPlatformTutorial", "LeftPrompt", "Activate Thruster");

		Player.ShowTutorialPrompt(PromptLeft, this);
		Player.ShowTutorialPrompt(PromptRight, this);	

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!HasControl())
			return;

		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		FVector Velocity;

		if (IsActioning(ActionNames::PrimaryLevelAbility))
		{
			PrintToScreen("RIGHT");
			Velocity += Platform.ActorRightVector * -MoveSpeed;
		}
		
		if (IsActioning(ActionNames::SecondaryLevelAbility))
		{
			PrintToScreen("LEFT");
			Velocity += Platform.ActorRightVector * MoveSpeed;
		}

		PrintToScreen("Velocity: " + Velocity);

		Platform.TargetVelocity += Velocity;
	}
}