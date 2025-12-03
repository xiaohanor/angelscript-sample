UCLASS(Abstract, meta = (DefaultActorLabel = "Knight"))
class AAISummitKnightBro : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightBroCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitAIGentlemanMeleeScoreCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFindTraversalAreaCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitLeapTraversalMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AISummitMeltCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightHideShieldCapability");

	UPROPERTY(DefaultComponent) 
	UBasicAICharacterMovementComponent MovementComponent;
	
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
	
	UPROPERTY(DefaultComponent)
	UTrajectoryTraversalComponent TraversalComp;
	default TraversalComp.Method = USummitLeapTraversalMethod;

	UPROPERTY(DefaultComponent)
	UBasicAIKnockdownComponent KnockdownComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);
	// default RequestCapabilityComp.PlayerSheets.Add(BaseTeenDragonStumbleSheet);

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = RightAttach)
	USummitKnightSpearComponent Spear;
	
	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = LeftAttach)
	USummitKnightShieldComponent Shield;

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltComp;
	default MeltComp.bMeltAllMaterials = false;

	UPROPERTY(DefaultComponent)
	USummitKnightCrystalFieldComponent CrystalFieldComp;

	UPROPERTY(DefaultComponent)
	USummitKnightPossessComponent PossessComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		MeltComp.OnMelted.AddUFunction(this, n"OnMelted");
		MeltComp.OnRestored.AddUFunction(this, n"OnRestored");
		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		UMovementGravitySettings::SetGravityScale(this, 10, this, EHazeSettingsPriority::Defaults);
		
		// We don't want the Knight to fly off the arena when knocked back
		UBasicAIMovementSettings::SetAirFriction(this, UBasicAIMovementSettings::GetSettings(this).GroundFriction, this);
		UBasicAIHealthBarSettings::SetHealthBarOffset(this, FVector(0,0,800), this);

		HealthComp.OnDie.AddUFunction(this, n"OnDieEvent");
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
		Spear.AddComponentVisualsBlocker(this);
		if(!PossessComp.bPossessed)
			return;
	}

	UFUNCTION()
	private void OnRestored()
	{
		Spear.RemoveComponentVisualsBlocker(this);
		if(!PossessComp.bPossessed)
			return;
	}
}