class AFloatingNightQueenIsland : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttackOrigin;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"FloatingIslandAttackCapability");

	UPROPERTY(DefaultComponent)
	UAdultDragonAcidSoftLockComponent SoftLockComp;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	TArray<UCageSpawnPoint> CageSpawnComps;

	UPROPERTY(EditAnywhere)
	ASummitNightQueenGem Gem;

	UPROPERTY(EditAnywhere)
	float AttackRange = 18000.0;

	UPROPERTY(EditAnywhere)
	float FireRate = 0.2;

	UPROPERTY(EditAnywhere)
	float WaitDuration = 1.5;

	UPROPERTY(EditAnywhere)
	int AttacksPerPlayer = 3;

	UPROPERTY()
	TSubclassOf<ASummitMagicTrajectoryProjectile> ProjectileClass;

	UPROPERTY()
	TSubclassOf<ANightQueenMetal> NightQueenMetalClass;
	UPROPERTY(EditAnywhere)
	TArray<ANightQueenMetal> InUseCageBars;

	UPROPERTY()
	float DestructionImpulseForce = 45000.0;

	UPROPERTY()
	UNiagaraSystem ExplosionSystem;

	TArray<UStaticMeshComponent> MeshArray;

	UFUNCTION(CallInEditor)
	void SpawnCageBars()
	{
		CageSpawnComps.Empty();
		GetComponentsByClass(CageSpawnComps);
		DeleteCageBars();

		for (UCageSpawnPoint Comp : CageSpawnComps)
		{
			ANightQueenMetal NightQueenMetal = SpawnActor(NightQueenMetalClass, Comp.WorldLocation);
			float HalfHeight = NightQueenMetal.BlockingVolume.ScaledBoxExtent.Z;
			NightQueenMetal.ActorLocation -= FVector(0.0, 0.0, HalfHeight);
			NightQueenMetal.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			InUseCageBars.Add(NightQueenMetal);
		}	
	}

	UFUNCTION(CallInEditor)
	void DeleteCageBars()
	{
		if (InUseCageBars.Num() == 0)
			return;

		for (ANightQueenMetal Metal : InUseCageBars)
		{
			if (Metal != nullptr)
				Metal.DestroyActor();
		}

		InUseCageBars.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(MeshArray);
		Gem.OnSummitGemDestroyed.AddUFunction(this, n"OnSummitGemDestroyed");	
		Gem.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}

	void SpawnProjectile(AHazeActor Target)
	{
		float RX = Math::RandRange(-800.0, 800.0);
		float RY = Math::RandRange(-800.0, 800.0);
		float RZ = Math::RandRange(-800.0, 800.0);
		FVector OffsetTarget = Target.ActorLocation + FVector(RX, RY, RZ);
		FRotator RotTarget = (OffsetTarget - AttackOrigin.WorldLocation).Rotation();

		// TODO: Use projectile launcher?
		ASummitMagicTrajectoryProjectile Proj = SpawnActor(ProjectileClass, AttackOrigin.WorldLocation, RotTarget, bDeferredSpawn = true);
		Proj.IgnoreActors.Add(this);
		Proj.TargetLocation = OffsetTarget;
		Proj.Speed = 9000.0;
		Proj.Gravity = 1200.0;

		for (ANightQueenMetal Metal : InUseCageBars)
		{
			Proj.IgnoreActors.Add(Metal);
		}

		Proj.Speed = 2200.0;
		FinishSpawningActor(Proj);
	}

	UFUNCTION()
	private void OnSummitGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
		for (ANightQueenMetal Metal : InUseCageBars)
		{
			Metal.BlockingVolume.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}

		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionSystem, ActorLocation, ActorRotation);

		for (UStaticMeshComponent Mesh : MeshArray)
		{
			Mesh.SetSimulatePhysics(true);
			FVector Impulse = (Mesh.WorldLocation - ActorLocation).GetSafeNormal() * DestructionImpulseForce;
			Mesh.AddImpulse(Impulse);
		}
	}
}

class UCageSpawnPoint : USceneComponent
{

}