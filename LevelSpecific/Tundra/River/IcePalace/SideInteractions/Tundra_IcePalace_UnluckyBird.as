class ATundra_IcePalace_UnluckyBird : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	USceneComponent HitVFXLocation;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem BirdHitVFX;

	default ActorHiddenInGame = true;
	FVector StartingLocation;
	FVector TargetLocation;
	float Duration = 0;
	float Timer = 0;
	bool bBirdActive = false;
	bool bHasBeenHit = false;
	float DeactivationTimer = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingLocation = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bBirdActive)
			return;

		DeactivationTimer += DeltaSeconds;

		if(!bHasBeenHit)
		{
			Timer += DeltaSeconds;
			float Alpha = Math::Clamp(Timer / Duration, 0, 1);
			SetActorLocation(Math::Lerp(StartingLocation, TargetLocation, Alpha));
			FRotator NewRot = FRotator::MakeFromXZ((TargetLocation - StartingLocation).GetSafeNormal(), FVector::UpVector);
			SetActorRotation(NewRot);

			if(Alpha >= 1)
			{
				bHasBeenHit = true;
				BirdHit();

				Online::UnlockAchievement(n"ThrowStones");
			}
		}

		if(DeactivationTimer >= 15)
			DestroyActor();
	}

	void BirdHit()
	{
		Mesh.SimulatePhysics = true;
		Mesh.AddVelocityChangeImpulseAtLocation(FVector(0, 0, -50000), ActorLocation + FVector(0, 0, 100));	
		Niagara::SpawnOneShotNiagaraSystemAtLocation(BirdHitVFX, HitVFXLocation.WorldLocation);
		
		FUnluckyBirdEventData Data;
		Data.UnluckyBird = this;
		UTundra_IcePalace_UnluckyBirdEventHandler::Trigger_OnUnluckyBirdHit(this, Data);

		BP_BirdBonkFF();
	}

	void ActivateUnluckyBird(FVector NewTargetLocation, float FlightDurationBeforeHit)
	{
		SetActorHiddenInGame(false);
		bBirdActive = true;
		TargetLocation = NewTargetLocation;
		Duration = FlightDurationBeforeHit;
		UTundra_IcePalace_UnluckyBirdEventHandler::Trigger_OnUnluckyBirdStarted(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_BirdBonkFF(){}
};