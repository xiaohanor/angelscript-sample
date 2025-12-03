event void FOnSummitPushableActivated();

class ASummitPushablePlatform : AHazeActor
{
	FOnSummitPushableActivated OnSummitPushableActivated;
 
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetMobility(EComponentMobility::Movable);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UStaticMeshComponent SymbolMesh;
	default SymbolMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UTeenDragonTailAttackResponseComponent TailResponseComp;
	default TailResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent CallBackComp;

	UPROPERTY(EditInstanceOnly)
	ASummitRaisablePillar Pillar;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeStart;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeEnd;

	UPROPERTY()
	UForceFeedbackEffect HitRumble;
	
	UPROPERTY()
	UForceFeedbackEffect LandRumble;

	float TargetRotation;
	float CurrentRotation;
	float EndRotation = -90;

	float HorizontalImpulseAmount = 2600.0;
	float VerticalImpulseAmount = 2000.0;

	bool bPlayedCameraShake;

	TArray<AHazePlayerCharacter> PlayersToLaunch;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Network::SetActorControlSide(this, Game::Zoe);
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		CallBackComp.OnAnyImpactByPlayer.AddUFunction(this, n"OnAnyImpactByPlayer");
		CallBackComp.OnAnyImpactByPlayerEnded.AddUFunction(this, n"OnAnyImpactByPlayerEnded");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentRotation = Math::FInterpConstantTo(CurrentRotation, TargetRotation, DeltaSeconds, Math::Abs(EndRotation * 3.0));
		RotateRoot.RelativeRotation = FRotator(CurrentRotation,0,0);

		if (!bPlayedCameraShake && CurrentRotation == TargetRotation)
		{
			bPlayedCameraShake = true;

			for (AHazePlayerCharacter Player : Game::Players)
			{
				Player.PlayWorldCameraShake(CameraShakeEnd, this, ActorLocation, 5000.0, 15000.0);
				Player.PlayForceFeedback(LandRumble, false, true, this, 1.2);
			}

			USummitPushablePlatformEffectHandler::Trigger_OnPushablePlatformStop(this);
		}
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		SetActorTickEnabled(true);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayWorldCameraShake(CameraShakeStart, this, ActorLocation, 5000.0, 15000.0);

			if (Player.IsZoe())
				Player.PlayForceFeedback(HitRumble, false, true, this);
		}

		TargetRotation = EndRotation;
		USummitPushablePlatformEffectHandler::Trigger_OnPushablePlatformStart(this);

		OnSummitPushableActivated.Broadcast();
	}

	void OnTimerCompleted()
	{
		TargetRotation = 0.0;
		bPlayedCameraShake = false;
		USummitPushablePlatformEffectHandler::Trigger_OnPushablePlatformStart(this);

		for (AHazePlayerCharacter Player : PlayersToLaunch)
		{
			FVector Impulse = -ActorForwardVector * HorizontalImpulseAmount;
			Impulse += FVector::UpVector * VerticalImpulseAmount;
			Player.AddMovementImpulse(Impulse);
		}
	}

	UFUNCTION()
	private void OnAnyImpactByPlayer(AHazePlayerCharacter Player)
	{
		PlayersToLaunch.AddUnique(Player);
	}

	UFUNCTION()
	private void OnAnyImpactByPlayerEnded(AHazePlayerCharacter Player)
	{
		PlayersToLaunch.Remove(Player);
	}

	UFUNCTION()
	void SetEndState()
	{
		RotateRoot.RelativeRotation = FRotator(EndRotation,0,0);;
		SetActorTickEnabled(false);
	}
};