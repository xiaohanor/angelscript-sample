class ASummitDarkCaveChainedPersimmonTree : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent)
	USummitDarkCaveSaveComponent SaveComp;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ANightQueenChain ChainHoldingTreeUp;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitDarkCaveBouncyPersimmon> PersimmonsToAttach;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FRotator UnchainedTargetRotation = FRotator(-60, 0, 0);

	UPROPERTY(EditAnywhere, Category = "Settings")
	// float RotationStiffness = 10.0;
	float RotationStiffness = 5.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotationDamping = 0.4;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PersimmonImpactImpulse = 10.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect Rumble;

	FHazeAcceleratedRotator AccTreeRotation;

	bool bIsChained = true;
	bool bPlayLandingFeedback = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ChainHoldingTreeUp.OnNightQueenMetalMelted.AddUFunction(this, n"OnChainMelted");

		for(auto Persimmon : PersimmonsToAttach)
		{
			Persimmon.AttachToComponent(RotateRoot, n"NAME_None", EAttachmentRule::KeepWorld);
			Persimmon.OnPlayerLandedOnPersimmon.AddUFunction(this, n"PlayerLandedOnPersimmon");
		}

		AccTreeRotation.SnapTo(RotateRoot.RelativeRotation);
		SaveComp.OnSummitDarkCaveActivateSave.AddUFunction(this, n"OnSummitDarkCaveActivateSave");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsChained)
			return;

		AccTreeRotation.SpringTo(UnchainedTargetRotation, RotationStiffness, RotationDamping, DeltaSeconds);
		RotateRoot.RelativeRotation = AccTreeRotation.Value;
		float RotDist = (FVector(AccTreeRotation.Value.Pitch) - FVector(UnchainedTargetRotation.Pitch)).Size();

		if (RotDist < 15.0 && !bPlayLandingFeedback)
		{
			bPlayLandingFeedback = true;
			PlayFeedback(0.5, 0.15);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnChainMelted()
	{
		bIsChained = false;
		PlayFeedback(1.0, 1.0);
		USummitDarkCaveChainedPersimmonTreeEventhandler::Trigger_Fall(this);
	}

	UFUNCTION()
	private void OnSummitDarkCaveActivateSave()
	{
		SetActorTickEnabled(false);
		RotateRoot.RelativeRotation = UnchainedTargetRotation;
		ChainHoldingTreeUp.AddActorDisable(this);
		
	}

	UFUNCTION()
	private void PlayerLandedOnPersimmon()
	{
		AccTreeRotation.Velocity += FRotator(-PersimmonImpactImpulse, 0, 0);
	}

	void PlayFeedback(float CamMult = 1.0, float RumbleMult = 1.0)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			float Distance = Player.GetDistanceTo(this);
			float Alpha = Math::Clamp(Distance / 8000.0, 0.0 ,0.8);
			Player.PlayForceFeedback(Rumble, false, false, this, Alpha * RumbleMult);
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 5000.0, 20000.0, Scale = CamMult);
		}
	}
};