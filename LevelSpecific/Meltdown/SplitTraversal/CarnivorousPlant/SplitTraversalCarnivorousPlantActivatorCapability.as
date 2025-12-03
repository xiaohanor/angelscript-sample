class USplitTraversalCarnivorousPlantActivatorCapability : UInteractionCapability
{
	ASplitTraversalCarnivorousPlantActivator PlantActivator;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		OnActivateBlendOut.BindUFunction(this, n"HandleActivateAnimBlendedOut");
	}

	bool bPushingButton = false;
	FHazeAnimationDelegate OnActivateBlendOut;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		PlantActivator = Cast<ASplitTraversalCarnivorousPlantActivator>(ActiveInteraction.Owner);

		PlantActivator.InteractingPlayer = Player;

		Player.AttachToComponent(PlantActivator.InteractComp, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		Player.ActivateCamera(PlantActivator.CameraActor, 2.0, this);

	//	Player.ApplyClampedPointOfInterest(this, PlantActivator.POITargetInfo, PlantActivator.POISettings, PlantActivator.POIClamps);

		Player.ShowTutorialPromptWorldSpace(PlantActivator.TutorialPrompt, this, PlantActivator.TutorialAttachComp, FVector::ZeroVector, 0.0);

		PlantActivator.Plant.Activate();

		PlantActivator.Widget.OnStartControlling(PlantActivator.Plant.IsTargetInRange());

		if(PlantActivator.Plant.bLostTarget && PlantActivator.Plant.IsTargetInRange())
		{
			PlantActivator.Plant.bLostTarget = false;
		}

		PlantActivator.InteractComp.OnEnterBlendingOut.AddUFunction(this, n"HandleEnterBlendOut");

		USplitTraversalCarnivorousPlantActivatorEventHandler::Trigger_OnStartInteract(PlantActivator);
		USplitTraversalCarnivorousPlantEventHandler::Trigger_OnActivatorInteractionStart(PlantActivator.Plant);
	}

	UFUNCTION()
	private void HandleEnterBlendOut(AHazePlayerCharacter InteractingPlayer,
	                                 UThreeShotInteractionComponent Interaction)
	{
		PlayMHAnim();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.StopSlotAnimation(EHazeSlotAnimType::SlotAnimType_Default);
		Player.DetachFromActor(EDetachmentRule::KeepWorld);

		Player.DeactivateCamera(PlantActivator.CameraActor);

		//PlantActivator.Plant.Deactivate();
		PlantActivator.Plant.StopControlling();
		PlantActivator.Widget.OnStopControlling();

		Player.RemoveTutorialPromptByInstigator(this);

		USplitTraversalCarnivorousPlantActivatorEventHandler::Trigger_OnStopInteract(PlantActivator);
		USplitTraversalCarnivorousPlantEventHandler::Trigger_OnActivatorInteractionStop(PlantActivator.Plant);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::WeaponFire) && !PlantActivator.bCoolDown && HasControl())
			CrumbActivate();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivate()
	{
		PlantActivator.Activate();
		PlayActivateAnim();
		bPushingButton = true;
	}

	UFUNCTION()
	private void HandleActivateAnimBlendedOut()
	{
		PlayMHAnim();
		bPushingButton = false;
	}
	
	private void PlayMHAnim()
	{
		FHazeSlotAnimSettings Settings;
		Settings.bLoop = true;
		Player.PlaySlotAnimation(PlantActivator.ControlAnim, Settings);
		
	}

	private void PlayActivateAnim()
	{
		FHazeSlotAnimSettings Settings;
		Settings.bLoop = false;
		Player.PlaySlotAnimation(PlantActivator.ActivateAnim, Settings);
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), OnActivateBlendOut, PlantActivator.ActivateAnim, false);
	}
};