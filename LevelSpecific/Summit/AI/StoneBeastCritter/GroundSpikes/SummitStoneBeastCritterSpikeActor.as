class ASummitStoneBeastCritterSpikeActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UDecalComponent DecalComp;
	default DecalComp.SetHiddenInGame(true);

	UHazeActorNetworkedSpawnPoolComponent SpawnPool;

	USummitStoneBeastCritterSettings Settings;

	private float SpawnTime;
	private FVector Offset = FVector(0,0,-25);
	private FVector StartScale = FVector(0.1, 0.1, 0.1);
	private FVector TargetScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		Mesh.SetHiddenInGame(true);
		DecalComp.SetHiddenInGame(true);
		TargetScale = Mesh.GetRelativeScale3D();
		Mesh.SetRelativeScale3D(StartScale);
		Mesh.SetRelativeLocation(Offset);
	}
	
	UFUNCTION()
	private void OnRespawn()
	{	
		SpawnTime = Time::GameTimeSeconds;
		Mesh.SetHiddenInGame(true);
		Mesh.SetRelativeScale3D(StartScale);
		Mesh.SetRelativeLocation(Offset);
		DecalComp.SetHiddenInGame(true);

		if(IsActorDisabled())
			RemoveActorDisable(this);
	}


	void Setup(AAISummitStoneBeastCritter Critter)
	{
		Settings = USummitStoneBeastCritterSettings::GetSettings(Critter);
		SpawnPool = Critter.GetOrCreateGroundSpikeSpawnPool();
	}

	void SetDecalHiddenInGame(bool bHideDecal)
	{
		DecalComp.SetHiddenInGame(bHideDecal);
	}

	// Show mesh, start scaling up
	void ActivateSpikes()
	{
		Mesh.SetHiddenInGame(false);
		
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(SpawnTime < SMALL_NUMBER)
			return;

		
		if(Time::GetGameTimeSince(SpawnTime) > Settings.AttackGroundSpikesDuration * 0.75)
		{
			// Retract spikes
			Mesh.RelativeLocation = Math::VInterpConstantTo(Mesh.RelativeLocation, Offset * 4, DeltaSeconds, Offset.Size() * 2.0);
			Mesh.RelativeScale3D = Math::VInterpConstantTo(Mesh.RelativeScale3D, StartScale * 0.5, DeltaSeconds, 0.5);
		}
		else if(Time::GetGameTimeSince(SpawnTime) > Settings.AttackGroundSpikesDuration * 0.5)
		{
			// Expose spikes
			Mesh.RelativeLocation = Math::VInterpConstantTo(Mesh.RelativeLocation, Offset * -1.0, DeltaSeconds, Offset.Size() * 8);
			Mesh.RelativeScale3D = Math::VInterpConstantTo(Mesh.RelativeScale3D, TargetScale, DeltaSeconds, TargetScale.Size() * 4);
		}
		

		// Expire
		if(Time::GetGameTimeSince(SpawnTime) > Settings.AttackGroundSpikesDuration)
		{
			AddActorDisable(this);
			RespawnComp.UnSpawn();
			SpawnPool.UnSpawn(this);	
			return;		
		}
	}
};