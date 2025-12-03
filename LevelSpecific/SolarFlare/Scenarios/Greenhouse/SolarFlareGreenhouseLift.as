event void FOnGreenhouseLiftComplete();

class ASolarFlareGreenhouseLift : AHazeActor
{
	UPROPERTY()
	FOnGreenhouseLiftComplete OnGreenhouseLiftComplete;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LiftRoot;

	UPROPERTY(DefaultComponent, Attach = LiftRoot)
	USceneComponent LiftExitDoor1;
	UPROPERTY(DefaultComponent, Attach = LiftRoot)
	USceneComponent LiftExitDoor2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CollisionBlocker;
	default CollisionBlocker.SetHiddenInGame(true);
	default CollisionBlocker.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY()
	FRuntimeFloatCurve LiftCurve;
	default LiftCurve.AddDefaultKey(0, 0);
	default LiftCurve.AddDefaultKey(0.2, 0.1);
	default LiftCurve.AddDefaultKey(0.85, 0.85);
	default LiftCurve.AddDefaultKey(1.0, 1);

	UPROPERTY(DefaultComponent)
	USolarFlareFireWaveReactionComponent ImpactComp;

	ASolarFlareSun Sun;

	FHazeAcceleratedFloat AccelMoveSpeed;

	float MoveTime = 9.0;
	float TimeUntilWave;
	float CurrentTime;
	bool bCanMove = false;

	FVector Offset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Offset = EndRoot.RelativeLocation - LiftRoot.RelativeLocation;
		ImpactComp.OnSolarFlareImpact.AddUFunction(this, n"OnSolarFlareImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Sun == nullptr)
			Sun = TListedActors<ASolarFlareSun>().GetSingle();

		float FlareOverallWaitDuration = Sun.WaitDuration + Sun.TelegraphDuration;
		float TimeTillWave = SolarFlareSun::GetTimeToWaveImpact();
		// float TimeMultiplier = 1.0 - (TimeTillWave / FlareOverallWaitDuration) + 1.5;
		float TimeMultiplier = 1.0 - (TimeUntilWave / FlareOverallWaitDuration) + 1.5;

		if (!bCanMove)
			return;

		if (CurrentTime >= MoveTime)
		{
			BP_OpenExitDoors();

			FGreenhouseLiftParams Params;
			Params.Location = ActorLocation;
			USolarFlareGreenhouseLiftEffectHandler::Trigger_OnLiftStopped(this, Params);
			USolarFlareGreenhouseLiftEffectHandler::Trigger_OnLiftOpenDoors(this, Params);

			SetActorTickEnabled(false);
			OnGreenhouseLiftComplete.Broadcast();
			return;
		}

		CurrentTime += DeltaSeconds * TimeMultiplier;
		CurrentTime = Math::Clamp(CurrentTime, 0.0, MoveTime);
		AccelMoveSpeed.AccelerateTo(LiftCurve.GetFloatValue(CurrentTime / MoveTime), 1.5, DeltaSeconds);
		LiftRoot.RelativeLocation = Offset * AccelMoveSpeed.Value;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenExitDoors() {}

	UFUNCTION()
	void ActivateLift()
	{
		bCanMove = true;
		FGreenhouseLiftParams Params;
		Params.Location = ActorLocation;
		USolarFlareGreenhouseLiftEffectHandler::Trigger_OnLiftStarted(this, Params);
		TimeUntilWave = SolarFlareSun::GetTimeToWaveImpact();
		// CollisionBlocker.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

		//If time till wave is below this value, greatly slow down the lift
		if (TimeUntilWave < 2.0)
		{
			TimeUntilWave += MoveTime + 3.0; //adding a bit more length to slow down the lift if time is below this
		}
	}
	
	UFUNCTION()
	private void OnSolarFlareImpact()
	{
		FGreenhouseLiftParams Params;
		Params.Location = ActorLocation;
		USolarFlareGreenhouseLiftEffectHandler::Trigger_OnLiftImpacted(this, Params);
	}

	UFUNCTION()
	void SetEndState()
	{
		SetActorTickEnabled(false);
		LiftRoot.RelativeLocation = EndRoot.RelativeLocation;
		LiftExitDoor1.RelativeLocation = FVector(0,0,350); 
		LiftExitDoor2.RelativeLocation = FVector(0,0,-350); 
	}
};