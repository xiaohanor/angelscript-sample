class ASummitDarkCaveMovableClimbSection : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent ClimbableMeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent StatueMeshComp;

	UPROPERTY(DefaultComponent, Attach = ClimbableMeshComp)
	UTeenDragonTailClimbableComponent ClimbComp;
	default ClimbComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(EditInstanceOnly)
	ASummitDarkCaveWindRotator WindRotator;

	UPROPERTY(EditInstanceOnly)
	AStaticCameraActor StaticCamera;

	UPROPERTY(EditInstanceOnly)
	ASummitDarkCaveChainedBallGoal Goal;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> WindStartCameraShake;

	UPROPERTY()
	UForceFeedbackEffect Rumble;

	UPROPERTY()
	UForceFeedbackEffect RumbleFInish;

	UPROPERTY()
	FRuntimeFloatCurve Curve;
	default Curve.AddDefaultKey(0.0, 0.0);
	default Curve.AddDefaultKey(1.0, 1.0);

	float Duration = 3.2;
	float CurrentTime;

	float RotationAmount = -90.0;

	bool bHaveActivatedWind;
	bool bHaveSlowedRotation;
	bool bPlayedFeedbackJuice;

	float RotationDelay = 1.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		TArray<AActor> Attached;
		GetAttachedActors(Attached);
		for (AActor Actor : Attached)
		{
			Actor.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld);
		}

		Goal.OnCompleted.AddUFunction(this, n"OnCompleted");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (RotationDelay > 0.0)
		{
			RotationDelay -= DeltaSeconds;
			return;
		}

		if (!bPlayedFeedbackJuice)
		{
			bPlayedFeedbackJuice = true;

			for (AHazePlayerCharacter Player : Game::Players)
			{
				Player.PlayCameraShake(CameraShake, this);
				Player.PlayForceFeedback(Rumble, true, true, this, 0.2);
			}
		}

		CurrentTime += DeltaSeconds;
		float Alpha = Math::Saturate(CurrentTime / Duration);
		float TargetRotation = RotationAmount * Curve.GetFloatValue(Alpha);
		MeshRoot.RelativeRotation = FRotator(0,TargetRotation,0);

		if (Alpha > 0.9 && !bHaveSlowedRotation)
		{
			bHaveSlowedRotation = true;
			for (AHazePlayerCharacter Player : Game::Players)
				Player.StopForceFeedback(this);
		}

		if (Alpha > 0.99 && !bHaveActivatedWind)
		{
			bHaveActivatedWind = true;
			WindRotator.TurnOn();
			Timer::SetTimer(this, n"DeactivateCamera", 1.5);
			for (AHazePlayerCharacter Player : Game::Players)
			{
				Player.PlayCameraShake(CameraShake, this, 2.0);
				Player.PlayForceFeedback(RumbleFInish, false, false, this);
			}
		}
	}

	UFUNCTION()
	private void OnCompleted()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ActivateCamera(StaticCamera, 3.0, this, EHazeCameraPriority::High);
			Player.BlockCapabilities(CapabilityTags::Input, this);
		}

		USummitDarkCaveMovableClimbSectionEventHandler::Trigger_OnStatueStartRotation(this);
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateCamera()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.DeactivateCameraByInstigator(this, 2.5);	
			Player.UnblockCapabilities(CapabilityTags::Input, this);
		}

		USummitDarkCaveMovableClimbSectionEventHandler::Trigger_OnStatueStopRotation(this);
	}

	UFUNCTION(DevFunction)
	void ActivatePuzleComplete()
	{
		OnCompleted();
	}

	UFUNCTION()
	void SetEndState()
	{
		MeshRoot.RelativeRotation = FRotator(0,RotationAmount,0);
		WindRotator.TurnOn();
		bHaveActivatedWind = true;
		bPlayedFeedbackJuice = true;
		bHaveSlowedRotation = true;
	}
}