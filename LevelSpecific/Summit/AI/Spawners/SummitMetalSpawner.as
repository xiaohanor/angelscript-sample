class ASummitMetalSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent Collision;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HazeActorSpawnerCapability");

	UPROPERTY(DefaultComponent)
	UAcidTailBreakableComponent AcidComp;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UHazeActorSpawnerComponent SpawnerComp;

	UPROPERTY(DefaultComponent)
	USummitMageCritterSpawnPattern SpawnPattern;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem DestroyFx;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		this.JoinTeam(SummitSpawnerTags::MetalSpawnerTeam);
		AcidComp.OnWeakenedByAcid.AddUFunction(this, n"OnAcid");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(SpawnPattern.bDoneSpawning)
		{
			SpawnerComp.DeactivateSpawner(this);
			SpawnPattern.bDoneSpawning = false;
		}
	}

	UFUNCTION()
	private void OnAcid()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(DestroyFx, ActorCenterLocation);
		this.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		this.LeaveTeam(SummitSpawnerTags::MetalSpawnerTeam);
	}

	void Spawn()
	{
		SpawnPattern.SpawnLocation = ActorLocation + ActorUpVector * 500;
		SpawnerComp.ActivateSpawner(this);
	}

	UFUNCTION()
	void DisableSpanwer()
	{
		SetActorHiddenInGame(true);
		Collision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	void EnableSpawner()
	{
		SetActorHiddenInGame(false);
		Collision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}
}