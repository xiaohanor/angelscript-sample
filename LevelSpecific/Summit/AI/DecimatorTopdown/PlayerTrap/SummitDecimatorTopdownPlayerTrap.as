UCLASS(Abstract)
class ASummitDecimatorTopdownPlayerTrap : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownPlayerTrapCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AISummitMeltCapability");

	UPROPERTY(DefaultComponent, BlueprintReadOnly)
	UStaticMeshComponent CrystalMesh;
	default CrystalMesh.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Ignore);
	default CrystalMesh.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
	default CrystalMesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
	default CrystalMesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacterAlternate, ECollisionResponse::ECR_Ignore);
	default CrystalMesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
    USummitMeltPartComponent MetalMesh;
	default MetalMesh.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Ignore);
	default MetalMesh.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
	default MetalMesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
	default MetalMesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacterAlternate, ECollisionResponse::ECR_Ignore);
	
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ProjectileMesh;
	default ProjectileMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltComp;
	default MeltComp.bMeltAllMaterials = false;	
	
	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponse;
	
	UPROPERTY(DefaultComponent)
	UTeenDragonRollAutoAimComponent RollAutoAimComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimComp;
	default AutoAimComp.AutoAimMaxAngle = 25.0;
	

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	default TailAttackResponseComp.ImpactType = ETailAttackImpactType::Enemy;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent, Attach="ProjectileMesh")
	UNiagaraComponent ProjectileVFX;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect PlayerTrapForceFeedback;

	// Reference to Decimator's PhaseComp
	UPROPERTY()
	USummitDecimatorTopdownPhaseComponent DecimatorPhaseComp;

	// Reference to the man himself
	UPROPERTY(BlueprintReadOnly)
	AAISummitDecimatorTopdown Decimator;

	UFUNCTION(BlueprintPure)
	EHazePlayer GetPlayerTarget()
	{
		if(Target != nullptr)
			return Target.Player;

		return EHazePlayer::MAX;
	}

	AHazePlayerCharacter Target;
	AHazePlayerCharacter OtherPlayer;
	FVector LaunchLocation;
	FVector LaunchVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
		HealthComp.OnDie.AddUFunction(this, n"OnDieEvent");
		RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(this);
		RespawnComp.OnRespawn.AddUFunction(HealthComp, n"Reset");				
	}

	void SetTarget(AHazePlayerCharacter PlayerTarget)
	{	
		Target = PlayerTarget;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}

	// Crumbed from BasicAIDeathCapability
	UFUNCTION()
	private void OnDieEvent(AHazeActor ActorBeingKilled)
	{		
		RespawnComp.UnSpawn();
	}

	UFUNCTION(BlueprintOverride)
	FVector GetActorCenterLocation() const
	{
		return ActorLocation + FVector::UpVector * 200;
	}
};