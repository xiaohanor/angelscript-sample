class USummitDecimatorTopdownShockwaveLauncherComponent : USceneComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY()
	TSubclassOf<AHazeActor> ShockwaveActorClass;
	
	UPROPERTY()
	FVector LaunchOffset = FVector::ZeroVector;

	AAISummitDecimatorTopdown DecimatorOwner;

	// Seconds in between launched shockwaves
	UPROPERTY()
	float LaunchInterval = 2.0;

	// Initial impulse speed of shockwaves
	UPROPERTY()
	float LaunchSpeed = 10000.0;

	UHazeActorLocalSpawnPoolComponent SpawnPool;

 	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		devCheck(ShockwaveActorClass.IsValid(), "" + Owner.Name + " has a launcher component with invalid shockwaves projectile class. Fix!");
		DecimatorOwner = Cast<AAISummitDecimatorTopdown>(Owner);
		
		SpawnPool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(ShockwaveActorClass, Owner);
	}
	
	void Launch()
	{		
		FHazeActorSpawnParameters SpawnParams; 
		SpawnParams.Spawner = this;
		
		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::WorldGeometry);
		Trace.UseLine();
		Trace.IgnoreActor(Owner);

		FHitResult Hit = Trace.QueryTraceSingle(LaunchLocation + FVector::UpVector * 500, LaunchLocation + FVector::DownVector * 500);
		FVector GroundLocation = Hit.ImpactPoint;
		if (Hit.bBlockingHit)
			SpawnParams.Location = GroundLocation;	
		else
			SpawnParams.Location = LaunchLocation;

		SpawnParams.Rotation = WorldRotation;
		
		ASummitDecimatorTopdownShockwaveActor Shockwave = Cast<ASummitDecimatorTopdownShockwaveActor>(SpawnPool.Spawn(SpawnParams));
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Shockwave);
		RespawnComp.OnSpawned(DecimatorOwner, SpawnParams);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedShockwave");
		Shockwave.SetOwner(DecimatorOwner);

		USummitDecimatorTopdownEffectsHandler::Trigger_OnShockwave(DecimatorOwner);
	} 

	UFUNCTION()
	private void OnUnspawnedShockwave(AHazeActor Shockwave)
	{
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Shockwave);
		RespawnComp.OnUnspawn.Unbind(this, n"OnUnspawnedShockwave");
		SpawnPool.UnSpawn(Shockwave);
	}
	
	UFUNCTION(BlueprintPure)
	FVector GetLaunchLocation() const property 
	{
		return WorldTransform.TransformPosition(LaunchOffset);
	}
}


