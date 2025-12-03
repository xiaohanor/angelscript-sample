class UTundra_River_BearTrapTriggerPlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ATundra_River_BearTrap> BearTrap;

	UPROPERTY()
	float KillTimeSeconds = 0.5;

	TArray<ATundra_River_BearTrapDeathVolume> CurrentlyOverlappedVolumes;
	UPlayerHealthComponent HealthComp;
	UPlayerMovementComponent MoveComp;
	UTundraPlayerTreeGuardianComponent TreeComp;

	float KillTimer = 0;
	bool bIsCurrentlyKilling = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComp = UPlayerHealthComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		TreeComp = UTundraPlayerTreeGuardianComponent::Get(Owner);
		HealthComp.OnReviveTriggered.AddUFunction(this, n"OnRespawned");
	}

	UFUNCTION()
	private void OnRespawned()
	{
		bIsCurrentlyKilling = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(KillTimer > 0)
		{
			KillTimer -= DeltaSeconds;
			if(KillTimer <= 0 && !HealthComp.bIsDead)
			{
				HealthComp.KillPlayer(FPlayerDeathDamageParams(), nullptr);
				bIsCurrentlyKilling = false;
			}
		}

		bool bCurrentlyOverlapping = false;
		for(auto Volume : CurrentlyOverlappedVolumes)
		{
			if(Volume.IsOverlappingActor(Owner))
			{
				bCurrentlyOverlapping = true;
				break;
			}
		}
		if(bCurrentlyOverlapping && !bIsCurrentlyKilling)
		{
			if(MoveComp.IsOnAnyGround())
			{
				KillPlayer();
				return;
			}

			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
			if(Player.IsZoe() && TreeComp.CurrentRangedGrapplePoint != nullptr)
			{
				KillPlayer();
				return;
			}
		}
	}

	void AddVolume(ATundra_River_BearTrapDeathVolume Volume)
	{
		CurrentlyOverlappedVolumes.AddUnique(Volume);
	}

	void RemoveVolume(ATundra_River_BearTrapDeathVolume Volume)
	{
		CurrentlyOverlappedVolumes.RemoveSingleSwap(Volume);
	}

	UFUNCTION()
	private void KillPlayer()
	{
		// TODO: Spawn a pooled Bear Trap

		KillTimer = KillTimeSeconds;
		bIsCurrentlyKilling = true;

		auto BearTrapInstance = SpawnActor(BearTrap, Owner.ActorLocation, FRotator::ZeroRotator, bDeferredSpawn = true);
		BearTrapInstance.BearTrapKillVolume.SetRelativeScale3D(FVector(4, 4, 4));
		BearTrapInstance.BearTrapTriggerVolume.CollisionEnabled = ECollisionEnabled::NoCollision;
		BearTrapInstance.bSpawned = true;
		FinishSpawningActor(BearTrapInstance);
		BearTrapInstance.OnBearTrapSpawned.Broadcast();
	}
};