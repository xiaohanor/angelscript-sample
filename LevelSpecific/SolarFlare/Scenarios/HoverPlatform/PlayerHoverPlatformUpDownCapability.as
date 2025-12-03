class UPlayerHoverPlatformUpDownCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"PlayerHoverPlatformUpDownCapability");
	
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
		if (UserComp.MovementMode != ESolarFlareHoverPlatformMovementMode::UpDown)
			return false;

		if (!UserComp.bActivated)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (UserComp.MovementMode != ESolarFlareHoverPlatformMovementMode::UpDown)
			return true;
		
		if (!UserComp.bActivated)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Platform = UserComp.Platform;

		FTutorialPrompt UpPrompt;
		UpPrompt.Action = ActionNames::PrimaryLevelAbility;
		UpPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		UpPrompt.Text = NSLOCTEXT("HoverPlatformTutorial", "UpPrompt", "Activate Thruster");
		FTutorialPrompt DownPrompt;
		DownPrompt.Action = ActionNames::SecondaryLevelAbility;
		DownPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		DownPrompt.Text = NSLOCTEXT("HoverPlatformTutorial", "DownPrompt", "Activate Thruster");

		Player.ShowTutorialPrompt(DownPrompt, this);
		Player.ShowTutorialPrompt(UpPrompt, this);

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
			Velocity += Platform.ActorUpVector * MoveSpeed;

		if (IsActioning(ActionNames::SecondaryLevelAbility))
			Velocity += Platform.ActorUpVector * -MoveSpeed;

		Platform.TargetVelocity += Velocity;
	}
}