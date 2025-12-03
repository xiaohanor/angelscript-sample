class USummitBouncyBirdNestEggInteractionCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitBouncyBirdNestEgg Egg;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);
		
		Egg = Cast<ASummitBouncyBirdNestEgg>(Params.Interaction.Owner);
		AimComp = UPlayerAimingComponent::Get(Player);

		FAimingSettings AimSettings;
		AimSettings.bShowCrosshair = false;
		AimSettings.bApplyAimingSensitivity = false;
		AimComp.StartAiming(this, AimSettings);

		FTutorialPrompt ThrowTutorial;
		ThrowTutorial.Action = ActionNames::PrimaryLevelAbility;
		Player.ShowTutorialPrompt(ThrowTutorial, this);

		Egg.AttachToActor(Player);
		Egg.SetActorLocation(Player.ActorCenterLocation + Player.ActorForwardVector * 50);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		AimComp.StopAiming(this);
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto AimTarget = AimComp.GetAimingTarget(this);

		FVector PlayerForward = AimTarget.AimDirection.ConstrainToPlane(FVector::UpVector);
		FRotator ForwardFacing = FRotator::MakeFromXZ(PlayerForward, FVector::UpVector);
		Player.SetActorRotation(ForwardFacing);

		if(WasActionStarted(ActionNames::PrimaryLevelAbility))
		{
			ThrowEgg(AimTarget);
			LeaveInteraction();
		}
	}

	void ThrowEgg(FAimingResult AimResult)
	{
		Egg.DetachFromActor(EDetachmentRule::KeepWorld);
		FVector Impulse 
			= FVector::UpVector * 500
			+ Player.ActorForwardVector * 1000;

		Egg.AngularVelocity += Impulse.CrossProduct(FVector::UpVector) * Egg.AngularVelocityMultiplier;
		
		Egg.bIsActive = true;
		Egg.AddMovementImpulse(Impulse);
	}
};