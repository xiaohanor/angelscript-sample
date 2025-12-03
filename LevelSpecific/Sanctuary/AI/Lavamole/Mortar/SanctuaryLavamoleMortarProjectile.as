event void FSanctuaryLavamoleMortarProjectileSpawnPoolEvent(FVector Location, FRotator Rotation);

UCLASS(Abstract)
class ASanctuaryLavamoleMortarProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 9.82;
	// default TraceType = 

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent Trail;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent TelegraphSpotLight;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface DecalMaterial;
	
	UDecalComponent DecalComp;

	float DurationBeforeCheckingHit = 1.0;

	UPROPERTY()
	float SpotLightIntensity = 5.0;

	UPROPERTY()
	float SpotLightHeight = 600.0;

	UPROPERTY()
	float ExpirationTime = 10.0;

	AHazeActor Owner;
	FVector AttackLocation;

	FHazeAcceleratedFloat AccIntensity;

	FSanctuaryLavamoleMortarProjectileSpawnPoolEvent OnWantsSpawnPool;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
		TelegraphSpotLight.DetachFromComponent(EDetachmentRule::KeepWorld);
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		if (DecalComp != nullptr)
			DecalComp.SetHiddenInGame(true);

		TelegraphSpotLight.SetHiddenInGame(true);
	}

	UFUNCTION()
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		USanctuaryLavamoleMortarProjectileEventHandler::Trigger_OnLaunch(this, FSanctuaryLavamoleMortarProjectileOnLaunchEventData(AttackLocation));
		if (DecalComp == nullptr)
			DecalComp = Decal::SpawnDecalAtLocation(DecalMaterial, FVector(100.0, 200.0, 200.0), AttackLocation, FRotator(-90, 0, 0));
		DecalComp.SetWorldLocation(AttackLocation);
		DecalComp.SetHiddenInGame(true);

		TelegraphSpotLight.SetWorldLocation(AttackLocation + FVector::UpVector * SpotLightHeight);
		TelegraphSpotLight.SetIntensity(0.0);
		AccIntensity.SnapTo(0.0);
		TelegraphSpotLight.SetHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		AccIntensity.SpringTo(SpotLightIntensity, 20.0, 0.3, DeltaTime);
		TelegraphSpotLight.SetIntensity(AccIntensity.Value);

		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));
		
		float AliveDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
		if (AliveDuration > DurationBeforeCheckingHit)
		{
			LavaComp.ManualEndOverlapWholeCentipedeApply();
			bool bHitPlayer = false;
			for(FVector Location: GetBodyLocations())
			{
				if(!ActorLocation.IsWithinDist(Location, 90))
					continue;
				LavaComp.OverlapSingleFrame(Location, 90, false);
				bHitPlayer = true;
			}

			if (Hit.bBlockingHit || bHitPlayer)
			{
				if (!bHitPlayer && !SanctuaryCentipedeDevToggles::Mole::NoMoleMortarPools.IsEnabled())
					OnWantsSpawnPool.Broadcast(ActorLocation, ActorRotation);
				ProjectileComp.Expire();
				USanctuaryLavamoleMortarProjectileEventHandler::Trigger_OnHit(this);
			}
		}

		if (AliveDuration > ExpirationTime)
			ProjectileComp.Expire();
	}

	private TArray<FVector> GetBodyLocations() const
	{
		TArray<FVector> Locations;
		UPlayerCentipedeComponent CentipedeComp = UPlayerCentipedeComponent::Get(Game::Mio);
		if(ensure(CentipedeComp != nullptr, "Can only target centipede players!"))
			Locations = CentipedeComp.GetBodyLocations();
		return Locations;
	}
}