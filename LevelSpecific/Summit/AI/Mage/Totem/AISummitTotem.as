class AAISummitTotem : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttackOrigin;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent TotemSpawnSystem;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"AISummitTotemShootCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AISummitTotemTargetingCapability");

	UPROPERTY(Category = "Setup")
	TSubclassOf<ASummitMageSpiritBall> SpiritBallClass;

	AHazePlayerCharacter Target;

	float MaxTargetDist = 8000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BP_TotemFire();
		SetActorTickEnabled(false);
	}

	void SpawnMageSpiritBall()
	{
		FRotator RotTarget = (Target.ActorCenterLocation - ActorCenterLocation).Rotation();

		// TODO: Use projectile launcher?
		ASummitMageSpiritBall Proj = SpawnActor(SpiritBallClass, AttackOrigin.WorldLocation, RotTarget, bDeferredSpawn = true);
		Proj.IgnoreActors.Add(this);
		Proj.Speed = 1200.0;
		FinishSpawningActor(Proj);

		BP_TotemFire();
	}

	UFUNCTION(BlueprintEvent)
	void BP_TotemWindBack() {}

	UFUNCTION(BlueprintEvent)
	void BP_TotemFire() {}
}