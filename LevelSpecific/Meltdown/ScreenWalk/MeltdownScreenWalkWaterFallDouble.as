event void FOnWaterfallBlocking();
event void FOnWaterfallNotBlocking();

class AMeltdownScreenWalkWaterFallDouble : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent WaterfallTop;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent WaterfallBottom;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent SplashEffect;

	UPROPERTY(EditAnywhere)
	AMeltdownScreenWalkWaterfallBlocker BlockerActor;

	UPROPERTY(DefaultComponent)
	UBoxComponent DeathZone;

	UPROPERTY()
	FOnWaterfallBlocking Blocked;

	UPROPERTY()
	FOnWaterfallNotBlocking NotBLocked;

	bool bHasBeenHit = false;

	UPROPERTY(EditAnywhere)
	APlayerSplineLockZone SplineLock;

	bool bHasEntered;

	bool bTakeDamage = true;

	bool bIsBlocked;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BlockerActor.IsBlocking.AddUFunction(this, n"Blocking");
		BlockerActor.IsNotBlocking.AddUFunction(this, n"NotBlocking");

		DeathZone.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
		DeathZone.OnComponentEndOverlap.AddUFunction(this, n"EndOverlap");

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bTakeDamage == true && bHasEntered == true)
		{
			SplineLock.DisableForPlayer(Game::Mio,this);
			Game::Mio.AddKnockbackImpulse(ActorRightVector, 1000, 600);
			if(!bIsBlocked)
			{
				Game::Mio.BlockCapabilities(CapabilityTags::GameplayAction,this);
				bHasBeenHit = true;
				bIsBlocked = true;
			}
		}

		if(Game::Mio.IsPlayerDeadOrRespawning() && bHasBeenHit)
		{
			SplineLock.EnableForPlayer(Game::Mio,this);

			if(bIsBlocked)
			{
				Game::Mio.UnblockCapabilities(CapabilityTags::GameplayAction, this);
				bIsBlocked = false;
			}
		}
	//		Game::Mio.DealBatchedDamageOverTime(2.0 * DeltaSeconds, FPlayerDeathParams());

	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		bHasEntered = true;

	}

	UFUNCTION()
	private void EndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                        UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		bHasEntered = false;
	}


	UFUNCTION()
	private void Blocking()
	{
		WaterfallBottom.SetHiddenInGame(true);
	//	SplashEffect.Activate();
		bTakeDamage = false;
		Blocked.Broadcast();
		
	}

	UFUNCTION()
	private void NotBlocking()
	{
		WaterfallBottom.SetHiddenInGame(false);
	//	SplashEffect.Deactivate();
		bTakeDamage = true;
		NotBLocked.Broadcast();
	}
};