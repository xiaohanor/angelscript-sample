UCLASS(Abstract, meta = (DefaultActorLabel = "KnightMiniboss"))
class AAISummitKnightBoss : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightBossCompoundCapability");
	//default CapabilityComp.DefaultCapabilities.Add(n"SummitAIGentlemanMeleeScoreCapability");
	//default CapabilityComp.DefaultCapabilities.Add(n"SummitLeapTraversalMovementCapability");
	//default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AISummitMeltCapability");
	//default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightHideShieldCapability");

	UPROPERTY()
	float HeightOffset = 300;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	default TailAttackResponseComp.ImpactType = ETailAttackImpactType::Enemy;

	UPROPERTY(DefaultComponent)
	UTeenDragonRollAutoAimComponent RollAutoAimComp;
	
	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;	
	
	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UBasicAIPerceptionComponent PerceptionComp;
	default PerceptionComp.Sight = USummitTeenDragonAIPerceptionSight();

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = Hips)
	UStaticMeshComponent Shard;
	default Shard.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Shard.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
	default Shard.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	USummitCameraShakeComponent CameraShakeComp;
	
	// UPROPERTY(DefaultComponent)
	// UTrajectoryTraversalComponent TraversalComp;
	// default TraversalComp.Method = USummitLeapTraversalMethod;

	UPROPERTY(DefaultComponent)
	UBasicAIKnockdownComponent KnockdownComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = RightAttach)
	USummitKnightSwordComponent Sword;

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltComp;
	default MeltComp.bMeltAllMaterials = false;

	UPROPERTY(DefaultComponent)
	USummitKnightCrystalFieldComponent CrystalFieldComp;

	UPROPERTY(DefaultComponent)
	USummitKnightPossessComponent PossessComp;

	float DefaultCollisionCapsuleHeight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		MeltComp.OnMelted.AddUFunction(this, n"OnMelted");
		MeltComp.OnRestored.AddUFunction(this, n"OnRestored");
		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		UMovementGravitySettings::SetGravityScale(this, 0, this, EHazeSettingsPriority::Defaults);

		DefaultCollisionCapsuleHeight = CapsuleComponent.GetRelativeLocation().Z;

		// We don't want the Knight to fly off the arena when knocked back
		UBasicAIMovementSettings::SetAirFriction(this, UBasicAIMovementSettings::GetSettings(this).GroundFriction, this);
		UBasicAIHealthBarSettings::SetHealthBarOffset(this, FVector(0,0,800), this);

		HealthComp.OnDie.AddUFunction(this, n"OnDieEvent");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector CollisionCapsule = CapsuleComponent.GetRelativeLocation();
		CollisionCapsule.Z = DefaultCollisionCapsuleHeight + HeightOffset;
		CapsuleComponent.SetRelativeLocation(CollisionCapsule);


		FVector MeshOffsetLocation = MeshOffsetComponent.GetRelativeLocation();
		MeshOffsetLocation.Z = HeightOffset;
		MeshOffsetComponent.SetRelativeLocation(MeshOffsetLocation);
	}

	UFUNCTION()
	private void OnDieEvent(AHazeActor ActorBeingKilled)
	{
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if(!PossessComp.bPossessed)
			return;
		if(!MeltComp.bMelted)
			return;
			
		HealthComp.TakeDamage(0.4, EDamageType::MeleeBlunt, Params.PlayerInstigator);
	}

	UFUNCTION()
	private void OnMelted()
	{
		Sword.AddComponentVisualsBlocker(this);
		if(!PossessComp.bPossessed)
			return;
	}

	UFUNCTION()
	private void OnRestored()
	{
		Sword.RemoveComponentVisualsBlocker(this);
		if(!PossessComp.bPossessed)
			return;
	}
}

namespace SummitKnightTags
{
	const FName SummitKnightBossTeam = n"SummitKnightBossTeam";
}