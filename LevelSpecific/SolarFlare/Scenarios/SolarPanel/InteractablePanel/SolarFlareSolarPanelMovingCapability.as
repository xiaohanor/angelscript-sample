class USolarFlareSolarPanelMovingCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	ASolarFlareSolarPanel Panel;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		UPlayerHealthComponent::Get(Player).OnDeathTriggered.AddUFunction(this, n"OnDeath");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnDeath()
	{
		if(IsActive())
			LeaveInteraction();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::MovementVerticalUp;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_UpDown;
		TutorialPrompt.Text = NSLOCTEXT("SolarPanel", "UpDownMove", "Move");
		
		Panel = Cast<ASolarFlareSolarPanel>(Params.Interaction.Owner);

		Player.ShowTutorialPrompt(TutorialPrompt, this);
		Player.PlaySlotAnimation(Panel.InteractionAnimation);

		Panel.bMoveInteractionIsActive = true;
		Panel.ApplySolarPanelCameraSettings(Player, true);
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.StopSlotAnimation();
		Player.RemoveTutorialPromptByInstigator(this);

		Panel.bMoveInteractionIsActive = false;
		Panel.ApplySolarPanelCameraSettings(Player, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(HasControl())
		{
			float ForwardInput = GetAttributeFloat(AttributeNames::MoveForward);

			FVector PanelMovement = Panel.PanelRoot.UpVector * ForwardInput * Panel.PanelMoveSpeed * DeltaTime; 
			FVector DesiredPanelLocation = Panel.PanelRoot.RelativeLocation + PanelMovement;

			DesiredPanelLocation = Panel.GetConstrictedLocation(DesiredPanelLocation);
			Panel.PanelRoot.RelativeLocation = DesiredPanelLocation;
		}
		else
		{

		}
	}
}