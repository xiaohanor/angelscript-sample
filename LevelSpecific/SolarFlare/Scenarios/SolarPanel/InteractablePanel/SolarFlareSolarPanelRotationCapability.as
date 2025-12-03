class USolarFlareSolarPanelRotationCapability : UInteractionCapability
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

		Panel = Cast<ASolarFlareSolarPanel>(Params.Interaction.Owner);

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::MovementVerticalUp;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_UpDown;
		TutorialPrompt.Text = NSLOCTEXT("SolarPanel", "UpDownRotate", "Rotate");

		Player.ShowTutorialPrompt(TutorialPrompt, this);
		Player.PlaySlotAnimation(Panel.InteractionAnimation);

		Panel.bRotationInteractionIsActive = true;
		Panel.ApplySolarPanelCameraSettings(Player, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.StopSlotAnimation();
		Player.RemoveTutorialPromptByInstigator(this);

		Panel.bRotationInteractionIsActive = false;
		Panel.ApplySolarPanelCameraSettings(Player, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(HasControl())
		{
			float RightInput = -GetAttributeFloat(AttributeNames::MoveForward);

			FRotator PanelRotation = FRotator(0, RightInput * Panel.PanelRotationSpeed * DeltaTime, 0);
			FRotator DesiredPanelRotation = Panel.PanelRoot.RelativeRotation + PanelRotation;

			if(Panel.bConstrictRotation)
				DesiredPanelRotation = Panel.GetConstrictedRotation(DesiredPanelRotation);

			Panel.PanelRoot.RelativeRotation = DesiredPanelRotation;
		}
		else
		{
			
		}
	}
}