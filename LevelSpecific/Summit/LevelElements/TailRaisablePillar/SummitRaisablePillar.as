class ASummitRaisablePillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ActivatorRotateRoot; 

	UPROPERTY(EditInstanceOnly)
	ASummitAcidActivatorActor AttachedAcidActivator;

	UPROPERTY()
	FRuntimeFloatCurve Curve;
	default Curve.AddDefaultKey(0.0, 0.0);
	default Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UForceFeedbackEffect LandRumble;

	FVector TargetLocation;
	FVector StartLocation;
	FVector StartOffset = FVector(0,0,-1100.0);

	float Duration = 1.25;
	float CurrentTime;
	float RotationAmount = 90;

	bool bPlayedCameraShake;

	bool bRising;
	bool bFinishedMoving;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Network::SetActorControlSide(this, Game::Mio);
		TargetLocation = ActorLocation;
		StartLocation = ActorLocation + StartOffset;
		ActorLocation = StartLocation;
		AttachedAcidActivator.AttachToComponent(ActivatorRotateRoot, NAME_None, EAttachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bRising)
			CurrentTime += DeltaSeconds;
		else	
			CurrentTime -= DeltaSeconds;

		CurrentTime = Math::Clamp(CurrentTime, 0.0, Duration);
		float Alpha = Math::Saturate(CurrentTime / Duration);
		float CurveAlpha = Curve.GetFloatValue(Alpha);

		ActorLocation = Math::Lerp(StartLocation, TargetLocation, CurveAlpha);
		ActivatorRotateRoot.RelativeRotation = FRotator(RotationAmount * Alpha,0,0);

		if (!bFinishedMoving && CurveAlpha > 0.99)
		{
			bFinishedMoving = true;

			for (AHazePlayerCharacter Player : Game::Players)
			{
				Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 5000.0, 15000.0);
				Player.PlayForceFeedback(LandRumble, false, true, this);
			}
		}
		
		if (!bFinishedMoving && CurveAlpha < 0.01)
		{
			bFinishedMoving = true;

			for (AHazePlayerCharacter Player : Game::Players)
			{
				Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 5000.0, 15000.0);
				Player.PlayForceFeedback(LandRumble, false, true, this);
			}
		}
	}

	void ActivateRaisable()
	{
		bRising = true;
		bFinishedMoving = false;
		USummitRaisablePillarEventHandler::Trigger_OnMoveUp(this);
	}

	void DeactivateRaisable()
	{
		bRising = false;
		bFinishedMoving = false;
		USummitRaisablePillarEventHandler::Trigger_OnMoveDown(this);
	}
};