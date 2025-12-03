namespace SummitDecimatorTopdown
{
	event void FSpikeBombExploded(FVector WorldLocation);
}

UCLASS(Abstract)
class AAISummitDecimatorSpikeBomb : ABasicAIGroundMovementCharacter
{
	// Do not use pathfinding, just move straight to destination
	default MoveToComp.DefaultSettings = BasicAICharacterGroundIgnorePathfindingSettings;

	default CapsuleComponent.RelativeLocation = FVector::ZeroVector;
	default CapsuleComponent.CapsuleHalfHeight = 110.0;
	default CapsuleComponent.CapsuleRadius = 110.0;

	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorSpikeBombBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AISummitMeltCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownBlobShadowCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorSpikeBombProjectileMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorSpikeBombRotateCapability");
	//default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorSpikebombChangeControlsideCapability"); // removed for having Decimator controlled by Zoe side all the time.

	// Tail components
	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	default TailAttackResponseComp.ImpactType = ETailAttackImpactType::Enemy;
	default TailAttackResponseComp.bShouldStopPlayer = false;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AcidAutoAimComp;
	default AcidAutoAimComp.AutoAimMaxAngle = 25.0;

    UPROPERTY(DefaultComponent, Attach = "CharacterMesh0")
    UStaticMeshComponent MeshCrystal;
	default MeshCrystal.CollisionProfileName = n"EnemyIgnoreCharacters";
	default MeshCrystal.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0")
    USummitMeltPartComponent MeshMetal;
	default MeshMetal.CollisionProfileName = n"EnemyIgnoreCharacters";
	default MeshMetal.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltComp;
	default MeltComp.bMeltAllMaterials = false;

	// For explosion
	UPROPERTY(DefaultComponent)
	USummitCameraShakeComponent CameraShakeComp;

	UPROPERTY(DefaultComponent)
	USummitDecimatorTopdownBlobShadowComponent BlobShadowComp;

	UPROPERTY(DefaultComponent)
    USummitDecimatorSpikeBombComponent SpikeBombComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbSyncPositionComp;
	default CrumbSyncPositionComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	USummitDecimatorSpikeBombSettings Settings;

	SummitDecimatorTopdown::FSpikeBombExploded OnSpikeBombExploded;

 	UPROPERTY(EditAnywhere)
	TSubclassOf<ASummitDecimatorSpikeBombExplosionTrail> ExplosionTrailSpawnClass;
	AAISummitDecimatorTopdown DecimatorOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		JoinTeam(DecimatorTopdownSpikeBombTags::SpikeBombTeamTag);

		Settings = USummitDecimatorSpikeBombSettings::GetSettings(this);
		UMovementGravitySettings::SetGravityScale(this, Settings.SpikeBombGravityScale, this, EHazeSettingsPriority::Defaults);

 		// We want fast reaction on Mio's side while melting.
		//this.SetActorControlSide(Game::Mio);
		
		OnSpikeBombExploded.AddUFunction(this, n"SpawnExplosionTrail");
		
		MeltComp.OnMelted.AddUFunction(this, n"OnMelted");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		AcidAutoAimComp.bIsAutoAimEnabled = true;
	}

	UFUNCTION()
	private void OnMelted()
	{
		AcidAutoAimComp.bIsAutoAimEnabled = false;
		USummitDecimatorSpikeBombEffectsHandler::Trigger_OnMelted(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		LeaveTeam(DecimatorTopdownSpikeBombTags::SpikeBombTeamTag);
	}

	// When Spikebomb explodes on the ground it leaves an explosion trail.	
	UFUNCTION()
	private void SpawnExplosionTrail(FVector WorldLocation)
	{	
		// Leave a mark on this world
		FHazeActorSpawnParameters SpawnParams;
		SpawnParams.Location = GetActorLocation();
		SpawnParams.Rotation = FRotator(0, Math::RandRange(0,180), 0);
				
		//UHazeActorLocalSpawnPoolComponent ExplosionTrailSpawnPool = DecimatorTopdown::Spikebomb::GetSpikebombExplosionTrailSpawnPool();
		AActor Actor = SpawnActor(ExplosionTrailSpawnClass, SpawnParams.Location, SpawnParams.Rotation, NAME_None, false, GetLevel());
        AHazeActor SpawnedActor = Cast<AHazeActor>(Actor);		
		//FinishSpawningActor(SpawnedActor);		

		ASummitDecimatorSpikeBombExplosionTrail ExplosionTrail = Cast<ASummitDecimatorSpikeBombExplosionTrail>(SpawnedActor);
		ExplosionTrail.Setup(Settings);

		// Explode afterwards, or the spawnpool will be unavailable.
		HealthComp.TakeDamage(1.0, EDamageType::Explosion, this);
	}
}

namespace DecimatorTopdownSpikeBombTags
{
	const FName SpikeBombTeamTag = n"SpikeBombTeam";
}