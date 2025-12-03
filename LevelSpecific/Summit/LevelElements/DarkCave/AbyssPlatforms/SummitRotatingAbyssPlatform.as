class ASummitRotatingAbyssPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent MeshRoot;

	UPROPERTY(EditInstanceOnly)
	ASummitAcidActivatorActor AcidActivator;

	UPROPERTY(EditInstanceOnly)
	APropLine Path;

	UPROPERTY(EditInstanceOnly)
	FRotator RotationTarget = FRotator(0, 0, 90);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve RotationCurve;
	default RotationCurve.AddDefaultKey(0.0, 0.0);
	default RotationCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve RumbleCurve;
	default RumbleCurve.AddDefaultKey(0.0, 0.0);
	default RumbleCurve.AddDefaultKey(0.25, 1.0);
	default RumbleCurve.AddDefaultKey(0.75, 1.0);
	default RumbleCurve.AddDefaultKey(1.0, 0.0);

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect RumbleFinish;

	UPROPERTY(EditInstanceOnly)
	float RotationDuration = 1.1;
	float CurrentAlpha;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	float MaxRumbleDistance = 8000.0;

	float TimeFromAcidActivated;
	float TelegraphMoveDownDuration = 3.0;

	bool bTelegraphed;
	bool bPlayedCameraShake;
	float SinTime;
	float MoveAlpha;

	bool bFinishedRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidActivator.OnAcidActorActivated.AddUFunction(this, n"OnAcidActorActivated");
		AcidActivator.OnAcidActorDeactivated.AddUFunction(this, n"OnAcidActorDeactivated");

		if (Path != nullptr)
			Path.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld);
		CurrentAlpha = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (AcidActivator.IsActivatorActive())
		{
			CurrentAlpha = Math::FInterpConstantTo(CurrentAlpha, 1.0, DeltaSeconds, 1 / RotationDuration);
			
			// RotationRoot.RelativeRotation = Math::QInterpConstantTo(RotationRoot.RelativeRotation.Quaternion(), FRotator(0).Quaternion(), DeltaSeconds, PI * RotationMultiplier).Rotator();

			if (Time::GameTimeSeconds > TimeFromAcidActivated + (AcidActivator.ActivateDuration - TelegraphMoveDownDuration) && !bTelegraphed)
			{
				bTelegraphed = true;
				SinTime = 0.0;
				MoveAlpha = 0.0;
				USummitRotatingAbyssPlatformEventHandler::Trigger_OnPlatformTelegraphGoDownStart(this);
			}

			if (bTelegraphed)
			{
				SinTime += DeltaSeconds;
				MoveAlpha = Math::Sin(SinTime * 25.0);
				MeshRoot.RelativeRotation = FRotator(0,0, MoveAlpha);
				USummitRotatingAbyssPlatformEventHandler::Trigger_OnPlatformTelegraphUpdateAlpha(this, FSummitRotatingAbyssPlatformAlphaParams(MoveAlpha));
			}

		}
		else
		{
			CurrentAlpha = Math::FInterpConstantTo(CurrentAlpha, 0.0, DeltaSeconds, 1 / RotationDuration);
			
			// RotationRoot.RelativeRotation = Math::QInterpConstantTo(RotationRoot.RelativeRotation.Quaternion(), RotationTarget.Quaternion(), DeltaSeconds, PI * RotationMultiplier).Rotator();

			if (bTelegraphed)
			{
				bTelegraphed = false;
				USummitRotatingAbyssPlatformEventHandler::Trigger_OnPlatformTelegraphGoDownEnd(this);
				MoveAlpha = Math::FInterpConstantTo(MoveAlpha, 0.0, DeltaSeconds, 1.0);
				MeshRoot.RelativeRotation = FRotator(0, 0, MoveAlpha);
			}
		}

		for (AHazePlayerCharacter Player : Game::Players)
		{
			float Multiplier = Math::Saturate((Player.ActorLocation - ActorLocation).Size() / MaxRumbleDistance);
			FHazeFrameForceFeedback ForceFeedback;
			ForceFeedback.LeftMotor = RumbleCurve.GetFloatValue(CurrentAlpha * RumbleCurve.GetFloatValue(Multiplier)) * 0.5;
			ForceFeedback.RightMotor = RumbleCurve.GetFloatValue(CurrentAlpha * RumbleCurve.GetFloatValue(Multiplier)) * 0.5;
			Player.SetFrameForceFeedback(ForceFeedback);
		}

		RotationRoot.RelativeRotation = FQuat::Slerp(RotationTarget.Quaternion(), FRotator(0.0).Quaternion(), RotationCurve.GetFloatValue(CurrentAlpha)).Rotator();

		if (!bFinishedRotation && CurrentAlpha > 0.99)
		{
			bFinishedRotation = true;

			for (AHazePlayerCharacter Player : Game::Players)
			{
				float Multiplier = Math::Saturate((Player.ActorLocation - ActorLocation).Size() / MaxRumbleDistance);
				Player.PlayForceFeedback(RumbleFinish, false, false, this, Multiplier * 1.5);
				Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 5000.0, 15000.0, 1.0);
			}

		}
	}
	
	UFUNCTION()
	private void OnAcidActorActivated()
	{
		TimeFromAcidActivated = Time::GameTimeSeconds;

		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 3000.0, 12000.0);

		USummitRotatingAbyssPlatformEventHandler::Trigger_OnPlatformMoveUp(this);
	}
	
	UFUNCTION()
	private void OnAcidActorDeactivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 3000.0, 12000.0);		

		USummitRotatingAbyssPlatformEventHandler::Trigger_OnPlatformMoveDown(this);
	}
};