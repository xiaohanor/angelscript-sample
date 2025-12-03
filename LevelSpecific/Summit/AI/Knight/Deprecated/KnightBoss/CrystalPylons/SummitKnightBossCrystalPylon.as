class ASummitKnightBossCrystalPylon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIDeathCapability");

	UPROPERTY(DefaultComponent, BlueprintReadOnly)
	UStaticMeshComponent CrystalMesh;
	//default CrystalMesh.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default CrystalMesh.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
	default CrystalMesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, BlueprintReadOnly)
	UStaticMeshComponent MetalMesh;

	UPROPERTY(DefaultComponent, EditDefaultsOnly)
	USceneComponent PylonTop;

	UPROPERTY(DefaultComponent)
	UTeenDragonRollAutoAimComponent RollAutoAimComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	default TailAttackResponseComp.ImpactType = ETailAttackImpactType::Enemy;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	USummitCameraShakeComponent CameraShakeComp;

	UPROPERTY(EditAnywhere)
	AAISummitKnightBoss KnightBoss;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		HealthComp.OnDie.AddUFunction(this, n"OnDieEvent");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		HealthComp.TakeDamage(1.4, EDamageType::MeleeBlunt, Params.PlayerInstigator);
	}

	UFUNCTION()
	private void OnDieEvent(AHazeActor ActorBeingKilled)
	{
		AddActorDisable(this);
	}
}