UCLASS(Abstract)
class AAIIslandRollotron : ABasicAIGroundMovementCharacter
{
	default CapsuleComponent.RelativeLocation = FVector::ZeroVector;

	default CapabilityComp.DefaultCapabilities.Add(n"IslandRollotronBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandRollotronUpdateMeshRotationCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandRollotronSpikeAnimCapability");
	
	UPROPERTY(DefaultComponent)
	UIslandRollotronSpikeComponent SpikeComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactResponseComponent ProjectileResponseComp;
	
	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);
	
	UPROPERTY(DefaultComponent, Attach=CharacterMesh0)
	UPoseableMeshComponent RollotronMesh;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueForceFieldCollisionComponent ForceFieldCollisionComp;
	default ForceFieldCollisionComp.AdditionalCollisionShapeTolerance = 37.5;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueReflectComponent BulletReflectComp;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	// Used by audio
	UPROPERTY(BlueprintReadWrite)
	FHazeAudioPostEventInstance ChargeUpEventInstance;

	float CachedSpeed = 0.0;
	FVector PreviousLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnReset();	
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CachedSpeed = (ActorLocation - PreviousLocation).Size() / DeltaSeconds;
		PreviousLocation = ActorLocation;

	}
	
	UFUNCTION()
	private void OnReset()
	{
	}
}