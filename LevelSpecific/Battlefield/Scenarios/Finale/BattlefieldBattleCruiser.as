class ABattlefieldBattleCruiser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent LargeSnowDust;
	default LargeSnowDust.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UBattlefieldHoverboardNoTurningSlopeComponent SlopeComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	FRuntimeFloatCurve SpeedCurve;
	default SpeedCurve.AddDefaultKey(0, 0.5);
	default SpeedCurve.AddDefaultKey(0.5, 1.0);
	default SpeedCurve.AddDefaultKey(0.75, 1.0);
	default SpeedCurve.AddDefaultKey(1.0, 0.4);

	UPROPERTY()
	FRuntimeFloatCurve RotationCurve;
	default RotationCurve.AddDefaultKey(0, 0);
	default RotationCurve.AddDefaultKey(1, 1);

	FRotator StartRot;
	FRotator TargetRot;
	float RotateOffset = 45.0;
	float MaxInterp = 0.12;
	float Interp = 0.12;

	float RotationDuration = 3.5;
	float ActiveDuration;

	bool bHaveShotCannon;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetRot = ActorRotation;
		StartRot = ActorRotation - FRotator(0,RotateOffset,0);
		SetActorRotation(StartRot);
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActiveDuration += DeltaSeconds;
		float Alpha = Math::Saturate(ActiveDuration / RotationDuration);
		ActorRotation = FQuat::Slerp(StartRot.Quaternion(), TargetRot.Quaternion(), RotationCurve.GetFloatValue(Alpha)).Rotator();
		// ActorRotation = Math::QInterpConstantTo(ActorRotation.Quaternion(), TargetRot.Quaternion(), DeltaSeconds, PI * Interp).Rotator();

		if (ActorRotation == TargetRot && !bHaveShotCannon)
		{
			bHaveShotCannon = true;
		}
	}

	UFUNCTION()
	void StartCannonReveal()
	{
		ActiveDuration = 0.0;
		SetActorTickEnabled(true);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayCameraShake(CameraShake, this);
		}
	}

	UFUNCTION()
	void ActivateFinalPosition()
	{
		ActorRotation = TargetRot;
	}

	UFUNCTION()
	private void OnBattlefieldReachedSplineEnd()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayCameraShake(CameraShake, this, 1.5);
		}		

		SetActorTickEnabled(false);
	}
}