class USummitTrapperTrapComponent : UActorComponent
{
	AHazeActor HazeOwner;

	UPROPERTY(Category = "Setup")
	TSubclassOf<ASummitTrapperTrap> TrapClass;
	ASummitTrapperTrap Trap;
	UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	UHazeActorSpawnPoolReserve SpawnPoolReserve;
	
	FVector TrapTargetLocation;
	AHazePlayerCharacter TrappedDragon;

	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FSummitTrapperReleasePlayerSignature OnReleasePlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);

		auto HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner);
		HealthComp.OnDie.AddUFunction(this, n"OnTrapperDie");

		auto AcidTailBreakComp = UAcidTailBreakableComponent::GetOrCreate(Owner);
		AcidTailBreakComp.OnWeakenedByAcid.AddUFunction(this, n"OnWeakenedByAcid");
		AcidTailBreakComp.OnBrokenByTail.AddUFunction(this, n"OnBrokenByTail");

		auto TailResponseComp = UTeenDragonTailAttackResponseComponent::GetOrCreate(Owner);
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnTailDragonRollImpact");

		SpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(TrapClass, Owner);
		SpawnPoolReserve = HazeActorSpawnPoolReserve::Create(Owner);
		SpawnPoolReserve.ReserveSpawn(SpawnPool);
	}

	UFUNCTION()
	private void OnTailDragonRollImpact(FRollParams Params)
	{
		ReleaseAll();
	}

	UFUNCTION()
	private void OnWeakenedByAcid()
	{
		ReleaseAll();
	}

	UFUNCTION()
	private void OnBrokenByTail(FOnBrokenByTailParams Params)
	{
		ReleaseAll();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{		
		if (Trap != nullptr)
			Debug::DrawDebugLine(HazeOwner.ActorCenterLocation, Trap.ActorCenterLocation, FLinearColor::Yellow, 10.0);
	}

	void SpawnTrap()
	{
		if(HasControl())
			CrumbSpawnTrap();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSpawnTrap()
	{
		Trap = Cast<ASummitTrapperTrap>(SpawnPoolReserve.Spawn());
		Trap.AddActorCollisionBlock(this);
		if(Trap.IsActorDisabled())
			Trap.RemoveActorDisable(this);
		Trap.SetActorLocationAndRotation(HazeOwner.ActorCenterLocation, HazeOwner.ActorRotation);		
		SpawnPoolReserve.ReserveSpawn(SpawnPool);
		Trap.OnTrapDestroyed.AddUFunction(this, n"OnTrapDestroyed");
	}

	UFUNCTION()
	void ReleaseTrap()
	{
		if(HasControl())
			CrumbReleaseTrap();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbReleaseTrap()
	{
		if(Trap == nullptr)
			return;
		
		Trap.AddActorDisable(this);
		SpawnPool.UnSpawn(Trap);
		Trap = nullptr;
	}

	UFUNCTION()
	private void OnTrapDestroyed()
	{
		ReleaseAll();
	}

	void TrapDragon(AHazePlayerCharacter Dragon)
	{
		if(HasControl())
			CrumbTrapDragon(Dragon);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTrapDragon(AHazePlayerCharacter Dragon)
	{
		//Effects Event for trap forming around the player
		Trap.RemoveActorCollisionBlock(this);
		TrappedDragon = Dragon;
		TrappedDragon.BlockCapabilities(CapabilityTags::Movement, this);
		TrappedDragon.BlockCapabilities((CapabilityTags::GameplayAction), this);
	}

	UFUNCTION()
	void ReleaseDragon()
	{
		if(HasControl())
			CrumbReleaseDragon();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbReleaseDragon()
	{
		if (TrappedDragon == nullptr)
			return;

		TrappedDragon.UnblockCapabilities(CapabilityTags::Movement, this);
		TrappedDragon.UnblockCapabilities((CapabilityTags::GameplayAction), this);
		TrappedDragon = nullptr;

		OnReleasePlayer.Broadcast();
	}
	
	UFUNCTION()
	private void OnTrapperDie(AHazeActor ActorBeingKilled)
	{
		ReleaseAll();
	}

	private void ReleaseAll()
	{
		if(!HasControl())
			return;

		CrumbReleaseDragon();
		CrumbReleaseTrap();
	}
}