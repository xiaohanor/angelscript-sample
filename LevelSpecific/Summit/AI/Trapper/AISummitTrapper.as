struct FSlingParams
{
	FVector TargetLocation;
}

event void FSummitTrapperReleasePlayerSignature();

UCLASS(Abstract, meta = (DefaultActorLabel = "Trapper"))
class AAISummitTrapper : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"AISummitMeltCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitTrapperCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFindTraversalAreaCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitGrappleTraversalMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");

	UPROPERTY(DefaultComponent) 
	UBasicAICharacterMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	default TailAttackResponseComp.ImpactType = ETailAttackImpactType::Enemy;

	//Activate for melting duration
	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UNiagaraComponent MeltingSystem;
	default MeltingSystem.SetAutoActivate(false);

	//Activate when dissolving
	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UNiagaraComponent DissolveSystem;
	default DissolveSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltingComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UBasicAIPerceptionComponent PerceptionComp;
	default PerceptionComp.Sight = USummitTeenDragonAIPerceptionSight();

	UPROPERTY(DefaultComponent)
	UAcidTailBreakableComponent AcidTailBreakComp;
	default AcidTailBreakComp.WeakenDuration = 2.5;
	default AcidTailBreakComp.AcidHitsNeededToWeaken = 200;
	default AcidTailBreakComp.TimeUntilRestore = 4.5;

	UPROPERTY(DefaultComponent)
	USceneComponent AttackOrigin;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent DarkMagicSystem;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UStaticMeshComponent Shard;
	default Shard.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Shard.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
	default Shard.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UAISummitTEMPEnemyMeshComponent TEMPSummitMeshComp;
	default TEMPSummitMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	USummitCameraShakeComponent CameraShakeComp;

	UPROPERTY(DefaultComponent)
	UTrajectoryTraversalComponent TraversalComp;
	default TraversalComp.Method = USummitGrappleTraversalMethod;

	UPROPERTY(DefaultComponent)
	UBasicAIKnockdownComponent KnockdownComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);

	UPROPERTY(DefaultComponent)
	USummitTrapperTrapComponent TrapComp;

	UPROPERTY(Category = "Setup")
	UAnimSequence PlayerEnterTrap;

	UPROPERTY(Category = "Setup")
	UAnimSequence PlayerTrapMh;

	UPROPERTY(Category = "Setup")
	UAnimSequence PlayerExitTrap;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		CapsuleComponent.QueueComponentForUpdateOverlaps();

		HealthComp.OnDie.AddUFunction(this, n"OnTrapperDie");

		AcidTailBreakComp.OnWeakenedByAcid.AddUFunction(this, n"OnWeakenedByAcid");
		AcidTailBreakComp.OnWeakenRestored.AddUFunction(this, n"OnWeakenRestored");
		AcidTailBreakComp.OnBrokenByTail.AddUFunction(this, n"OnBrokenByTail");
		
		auto TailResponseComp = UTeenDragonTailAttackResponseComponent::GetOrCreate(this);
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnTailDragonRollImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Multiplier = Math::Sin(Time::GameTimeSeconds * 2.0);
		FVector BobbingLoc = FVector(0.0, 0.0, 15.0 * Multiplier);
		MeshOffsetComponent.RelativeLocation = BobbingLoc;
	}

	UFUNCTION()
	private void OnTailDragonRollImpact(FRollParams Params)
	{
		KnockdownComp.Knockdown(EBasicAIKnockdownType::Default, FVector(0.0));

		if(!AcidTailBreakComp.IsWeakened())
			return;

		MovementComponent.AddPendingImpulse(Params.RollDirection * 100.0);
		HealthComp.TakeDamage(1000, EDamageType::MeleeBlunt, Params.PlayerInstigator);
	}

	UFUNCTION()
	private void OnWeakenedByAcid()
	{	
		Mesh.SetVisibility(false, true);
	} 

	UFUNCTION()
	private void OnWeakenRestored()
	{
		Mesh.SetVisibility(true, true);
		Mesh.SetVisibility(false, false);
	} 

	UFUNCTION()
	private void OnBrokenByTail(FOnBrokenByTailParams Params)
	{
		HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::Acid, this);
		FSummitAIArmorEnemyParams EffectParams;
		EffectParams.Location = ActorCenterLocation;
		EffectParams.Rotation = ActorRotation;
		UAISummitArmorEnemyEffectsHandler::Trigger_ShardDestroyed(this, EffectParams);
	}
	
	UFUNCTION()
	private void OnTrapperDie(AHazeActor ActorBeingKilled)
	{
		Mesh.SetVisibility(true, true);
		Mesh.SetVisibility(false, false);
	}
}