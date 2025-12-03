event void FOnCrystalSiegerJumpTransition();
event void FOnCrystalSiegerDefeated();

//Some crystal attacks
//short enemy wave 1
//short enemy wave 2 + mild attacks
//Rage
//Finsher

class ACrystalSieger : AHazeActor
{
	UPROPERTY()
	FOnCrystalSiegerDefeated OnCrystalSiegerDefeated;
	
	UPROPERTY()
	FOnCrystalSiegerJumpTransition OnCrystalSiegerJumpTransition;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComp;
	default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
	default CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Block);
	default CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Overlap);
	default CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MortarOrigin;

	//Some kind of rage lightning effect + stone cracking at the base
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent RageComponent;
	default RageComponent.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	// default CapabilityComp.DefaultCapabilities.Add(n"CrystalSiegerIntroAttackCapability");
	// default CapabilityComp.DefaultCapabilities.Add(n"CrystalSiegerExposedAttacksCapability");
	// default CapabilityComp.DefaultCapabilities.Add(n"CrystalSiegerMildAttackCapability");
	// default CapabilityComp.DefaultCapabilities.Add(n"CrystalSiegerRageAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"CrystalSiegerLineAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"CrystalSiegerCircleAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"CrystalSiegerMortarAttacksCapability");

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent OffsetComp;

	UPROPERTY(DefaultComponent)
	UDragonSwordCombatResponseComponent ResponseComp;

	UPROPERTY(EditAnywhere)
	AHazeActorIntervalSpawner Spawner1;

	UPROPERTY(EditAnywhere)
	AStoneBreakableActor ExposedBreakableActor;

	UPROPERTY(EditAnywhere)
	TArray<ACrystalSpikeRupture> SpikeRuptureBlockers;

	UPROPERTY(EditAnywhere)
	TArray<ACrystalSiegeLineAttackActor> LineAttackActors;

	UPROPERTY(EditAnywhere)
	TArray<ACrystalSiegeLineAttackActor> CircleLineAttackActors;

	UPROPERTY(EditAnywhere)
	TArray<ACrystalSiegeLineAttackActor> HorizontalLineAttackActors;

	UPROPERTY(EditAnywhere)
	ACrystalSiegerMortarArea CrystalSiegerMortarArea;

	bool bIntroAttack;
	bool bMildAttack;
	bool bExposedAttack;
	bool bRageAttack;

	//NEW ATTACKS
	UPROPERTY(EditAnywhere)
	ACrystalSiegeLineAttackActor LineAttackActor;

	UPROPERTY(EditAnywhere)
	ACrystalSiegeLineAttackActor CircleAttack;

	bool bLineAttacks;
	bool bCircleAttacks;
	bool bMortarAttacks;

	int HitCount;

	bool bWasHit;
	bool bSiegerEnabled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ExposedBreakableActor.AddActorDisable(this);
		ExposedBreakableActor.OnStoneBreakableActorDestroyed.AddUFunction(this, n"OnStoneBreakableActorDestroyed");

		ResponseComp.OnHit.AddUFunction(this, n"OnHit");

		AddActorDisable(this);
	}

	UFUNCTION()
	void InitiateAttackLocations()
	{
		LineAttackActor.ActorLocation = ActorLocation;
		CircleAttack.ActorLocation = ActorLocation;
	}

	UFUNCTION()
	void ActivateSieger()
	{
		RemoveActorDisable(this);
	}

	UFUNCTION()
	void ActivateBlockingRuptures()
	{
		for (ACrystalSpikeRupture Spike : SpikeRuptureBlockers)
		{
			Spike.ActivateSpikeRupture();
		}
	}

	UFUNCTION()
	void SetBlockingRupturesEndState()
	{
		for (ACrystalSpikeRupture Spike : SpikeRuptureBlockers)
		{
			Spike.SetSpikeRuptureEndState();
		}
	}

	UFUNCTION()
	private void OnHit(UDragonSwordCombatUserComponent CombatComp, FDragonSwordHitData HitData, AHazeActor Instigator)
	{
		HitCount++;
		bWasHit = true;
		PhaseCheck();
	}

	bool ConsumeHit()
	{
		if (bWasHit)
		{
			bWasHit = false;
			return true;
		}

		return false;
	}

	void ResetHit()
	{
		bWasHit = false;
	}

	void PhaseCheck()
	{
		if (HitCount == 3)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				float Distance = Player.GetDistanceTo(this);

				if (Distance < CapsuleComp.CapsuleRadius + 300.0)
				{
					FStumble Stumble;
					FVector Dir = (Player.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal() + FVector(0,0,1);
					Stumble.Move = FVector::UpVector * 15000;
					Stumble.Duration = 2;
					Player.ApplyStumble(Stumble);
				}	
			}

			bLineAttacks = false;
			bCircleAttacks = false;
			OnCrystalSiegerJumpTransition.Broadcast();
		}
	}

	UFUNCTION()
	void StartSiegerBattle()
	{
		bSiegerEnabled = true;
		ActivatePhaseOne();
	}

	// UFUNCTION()
	// void StartSiegerFinalPhase()
	// {
	// 	bSiegerEnabled = true;
	// 	ActivatePhaseFive();
	// 	ExposedBreakableActor.RemoveActorDisable(this);
	// }

	UFUNCTION()
	void EndSiegerBattle()
	{
		bSiegerEnabled = false;
	}

	//*** PHASE ONE ***//
	void ActivatePhaseOne()
	{
		bLineAttacks = true;
		bCircleAttacks = true;
		// bMortarAttacks = true;
		// bIntroAttack = true;
	}

	//*** PHASE TWO ***//
	void ActivatePhaseTwo()
	{
		bMildAttack = true;
	}

	// UFUNCTION()
	// private void OnDepletedTwo(AHazeActor LastActor)
	// {
	// 	Timer::SetTimer(this, n"ActivatePhaseThree", 3.5);
	// }

	// //*** PHASE THREE ***//
	// UFUNCTION()
	// void ActivatePhaseThree()
	// {
	// 	bMildAttack = false;
	// 	bRageAttack = true;
	// }	

	// //*** PHASE FOUR ***//
	// void ActivatePhaseFour()
	// {
	// 	bRageAttack = false;
	// 	ExposedBreakableActor.RemoveActorDisable(this);
	// }

	// UFUNCTION()
	// void ExposedSequenceComplete()
	// {
	// 	ActivatePhaseFive();
	// }

	// //*** PHASE FIVE ***//
	// void ActivatePhaseFive()
	// {
	// 	bExposedAttack = true;
	// }

	UFUNCTION()
	private void OnStoneBreakableActorDestroyed()
	{
		bSiegerEnabled = false;
		bExposedAttack = false;
		Spawner1.DeactivateSpawner();
		Spawner1.SpawnerComp.DisableSpawnedActors(this);
		OnCrystalSiegerDefeated.Broadcast();
	}
}