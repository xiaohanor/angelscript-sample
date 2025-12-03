class UOilRigShipHijackPlayerCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	AOilRigShipHijackPanel Panel;

	bool bLeftSide = true;

	AHazeCameraActor Camera;
	bool bTutorialActive;
	bool bBlockedCancel;
	bool bShownTutorial;

	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		if (!CheckInteraction.Owner.IsA(AOilRigShipHijackPanel))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		Panel = Cast<AOilRigShipHijackPanel>(ActiveInteraction.Owner);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::Interaction);

		ActiveInteraction.BlockCancelInteraction(Player, this);
		bBlockedCancel = true;

		Player.ActivateCamera(Panel.CameraComp, 2.0, this, EHazeCameraPriority::High);

		bTutorialActive = true;
		bShownTutorial = false;

		Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		Player.AddLocomotionFeature(Panel.LocomotionFeatures[Player], this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Camera != nullptr)
			Player.DeactivateCamera(Camera);
		
		Player.DeactivateCamera(Panel.CameraComp);

		Player.RemoveTutorialPromptByInstigator(this);

		Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);

		if (bBlockedCancel)
		{
			ActiveInteraction.UnblockCancelInteraction(Player, this);
			bBlockedCancel = false;
		}

		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bBlockedCancel && ActiveDuration > 0.4)
		{
			ActiveInteraction.UnblockCancelInteraction(Player, this);
			bBlockedCancel = false;
		}

		if (!bShownTutorial && bTutorialActive && ActiveDuration > 2.0)
		{
			FTutorialPrompt TutorialPrompt;
			TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;
			TutorialPrompt.Text = Panel.TutorialText;
			Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, Panel.TutorialAttachmentComp, FVector::ZeroVector, 0.0);
			bShownTutorial = true;
		}

		if (HasControl())
		{
			if (WasActionStarted(ActionNames::PrimaryLevelAbility) && ActiveDuration > 2.0)
			{
				if (Panel.TriggerButtonPressed())
				{
					if (bTutorialActive)
						CrumbRemoveTutorial();
				}
			}
		}

		if (Player.Mesh.CanRequestLocomotion())
			Player.Mesh.RequestLocomotion(n"HackShip", this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbRemoveTutorial()
	{
		bTutorialActive = false;
		Player.RemoveTutorialPromptByInstigator(this);
	}
}