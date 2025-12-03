class AAICoastPoltroon : AHazeCharacter
{
	default CapsuleComponent.bOffsetBottomToAttachParentLocation = false;
	default CapsuleComponent.bGenerateOverlapEvents = false;
	default CapsuleComponent.CollisionProfileName = n"EnemyIgnoreCharacters";
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIUpdateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"CoastPoltroonCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"CoastPoltroonDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAITakeDamageCapability");

    UPROPERTY(DefaultComponent)
	UBasicAIAnimationComponent AnimComp;
	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::Movement;

	UPROPERTY(DefaultComponent)
	UBasicAIDestinationComponent DestinationComp;

	UPROPERTY(DefaultComponent, ShowOnActor, meta = (ShowOnlyInnerProperties))
    UBasicBehaviourComponent BehaviourComponent;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=RightAttach)
	UHazeSkeletalMeshComponentBase Weapon;

	UPROPERTY(DefaultComponent, Attach=Weapon)
	UCoastPoltroonMuzzleComponent MuzzleComp;

	UPROPERTY(DefaultComponent)
	UCoastPoltroonAttackComponent AttackComp;

	UPROPERTY(DefaultComponent)
	UCoastShoulderTurretGunResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Spine2)
	UAutoAimTargetComponent AutoAimComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComp.OnDie.AddUFunction(this, n"OnDied");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		ResponseComp.OnBulletHit.AddUFunction(this, n"OnBulletHit");
	}

	UFUNCTION()
	private void OnDied(AHazeActor ActorBeingKilled)
	{
		AutoAimComp.bIsAutoAimEnabled = false;
	}

	UFUNCTION()
	private void OnBulletHit(FCoastShoulderTurretBulletHitParams Params)
	{
		HealthComp.TakeDamage(1000, EDamageType::Explosion, Params.PlayerInstigator);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnReset()
	{
		AttachToActor(RespawnComp.Spawner.AttachParentActor, NAME_None, EAttachmentRule::KeepWorld);
	}
}