class USplitTraversalControllableTurretCapability : UInteractionCapability
{
	ASplitTraversalControllableTurret ControllableTurret;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		ControllableTurret = Cast<ASplitTraversalControllableTurret>(ActiveInteraction.Owner);

		Player.AttachToComponent(ControllableTurret.InteractComp, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		
		//Player.PlaySlotAnimation(Animation = ControllableTurret.ControlAnim, bLoop = true);

		Player.ActivateCamera(ControllableTurret.CameraActor, 2.0, this);

		Player.ShowTutorialPrompt(ControllableTurret.TutorialPrompt, this);

		ControllableTurret.LaserMeshComp.SetHiddenInGame(false, true);

		USplitTraversalControllableTurretEventHandler::Trigger_OnInteractionStarted(ControllableTurret);

		ControllableTurret.InteractComp.OnEnterBlendingOut.AddUFunction(this, n"HandleEnterBlendOut");
	}

	UFUNCTION()
	private void HandleEnterBlendOut(AHazePlayerCharacter InteractingPlayer,
	                                 UThreeShotInteractionComponent Interaction)
	{
		InteractingPlayer.PlayBlendSpace(ControllableTurret.AimBlendSpace);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.DetachFromActor(EDetachmentRule::KeepWorld);

		//Player.StopAllSlotAnimations();

		Player.DeactivateCamera(ControllableTurret.CameraActor);

		Player.RemoveTutorialPromptByInstigator(this);

		ControllableTurret.YawForceComp.Force = FVector::ZeroVector;
		ControllableTurret.PitchForceComp.Force = FVector::ZeroVector;

		ControllableTurret.LaserMeshComp.SetHiddenInGame(true, true);

		Player.StopBlendSpace();

		USplitTraversalControllableTurretEventHandler::Trigger_OnInteractionStopped(ControllableTurret);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!ControllableTurret.bIsInteracting)
		{
			ControllableTurret.YawForceComp.Force = FVector::ZeroVector;
			ControllableTurret.PitchForceComp.Force = FVector::ZeroVector;
			return;
		}

		FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		FVector2D CamInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);

		MoveInput.X = Math::Clamp(MoveInput.X + CamInput.X, -1.0, 1.0);
		MoveInput.Y = Math::Clamp(MoveInput.Y + CamInput.Y, -1.0, 1.0);							
		
		ControllableTurret.YawForceComp.Force = FVector::ForwardVector * MoveInput.X * ControllableTurret.YawForce;
		ControllableTurret.PitchForceComp.Force = FVector::ForwardVector * MoveInput.Y * ControllableTurret.PitchForce;

		float PitchBlendSpaceValue = Math::GetMappedRangeValueClamped(FVector2D(-15.0, -35.0), FVector2D(0.0, 1.0), ControllableTurret.TurretPitchRoot.RelativeRotation.Pitch);

		PrintToScreen("RelativeRotation" + ControllableTurret.TurretPitchRoot.RelativeRotation.Pitch);
		PrintToScreen("PitchBlendSpaceValue" + PitchBlendSpaceValue);

		Player.SetBlendSpaceValues(MoveInput.X, PitchBlendSpaceValue);

		if (WasActionStarted(ActionNames::WeaponFire) && !ControllableTurret.bCoolDown)
			ControllableTurret.CrumbShoot();
	}
};