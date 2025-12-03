event void FSkylineJetpackCombatZoneExplodeSignature(ASkylineJetpackCombatZone Zone);

class ASkylineJetpackCombatZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent ExplodeEffect;
	default ExplodeEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UDecalComponent ExplodeIndicator;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BrokenMesh;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	TSubclassOf<AJetpackCombatZoneRocket> RocketClass;
	AJetpackCombatZoneRocket Rocket;

	UPROPERTY(EditAnywhere)
	TArray<AActor> Meshes;

	UPROPERTY(DefaultComponent)
	USpotLightComponent SpotLight;

 	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "DummyMoveToCombatZoneManager")
 	TSubclassOf<UBossHealthBarWidget> HealthBarWidgetClass;

 	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "DummyMoveToCombatZoneManager")
	FText HealthBarDesc;

	FSkylineJetpackCombatZoneExplodeSignature OnExplode;
	FSkylineJetpackCombatZoneExplodeSignature OnTelegraphExplosion;

	float StartTime;
	float TelegraphDuration = 5;
	float OffsetDuration = 0;
	float ExplodeTime = 0.0;
	FVector RocketStartLocation;
	AHazeActor CurrentlyOccupiedBy = nullptr; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ExplodeIndicator.SetVisibility(false);
		BrokenMesh.AddComponentVisualsBlocker(this);
		BrokenMesh.AddComponentCollisionBlocker(this);
	}

	UFUNCTION()
	void StartExploded()
	{
		for(auto Mesh: Meshes)
			Mesh.DestroyActor();

		OnExploded();		

		DestroyActor();
	}

	UFUNCTION(DisplayName = "StartExplosion_DEPRECATED_RemoveThis")
	void StartExplosion(FVector InRocketStartLocation)
	{
		if (StartTime > 0)
			return;
		if (World.IsTearingDown())		
			return; // PIE is ending

		// Rocket explosions are deprecated
	}

	void TelegraphExplosion()
	{
		OnTelegraphExplosion.Broadcast(this);
	}

	void Explode(FVector Direction, float Force)
	{
		for(AHazePlayerCharacter Player: Game::Players)
		{
			if(Player.ActorLocation.IsWithinDist(ActorLocation, 500))
				Player.DamagePlayerHealth(0.5);
		}
		Game::Mio.PlayCameraShake(CameraShake, this);
		Game::Zoe.PlayCameraShake(CameraShake, this);
		ExplodeEffect.Activate();
		ExplodeIndicator.SetVisibility(false);
		if (Rocket != nullptr)
			Rocket.DestroyActor();
		for(auto Mesh: Meshes)
			Mesh.DestroyActor();
		ExplodeTime = Time::GameTimeSeconds;

		OnExploded();
	}

	void OnExploded()
	{
		SpotLight.SetIntensity(0.0);
		SpotLight.SetVisibility(false);

		BrokenMesh.RemoveComponentVisualsBlocker(this);
		BrokenMesh.RemoveComponentCollisionBlocker(this);

		OnExplode.Broadcast(this);
	}
}

