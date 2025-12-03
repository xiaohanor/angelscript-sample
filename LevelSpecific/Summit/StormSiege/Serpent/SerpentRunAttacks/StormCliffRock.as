class AStormCliffRock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot, ShowOnActor)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StormCliffRockMovementCapability");

	UPROPERTY(DefaultComponent)
	UAdultDragonTakeDamageDestructibleRocksComponent DestructibleRocksComp;

	UPROPERTY(EditAnywhere)
	float OutImpulse = 3000.0;

	UPROPERTY(EditAnywhere)
	float MaxGravity = 12000.0;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.bDrawDisableRange = true;
	default DisableComp.AutoDisableRange = 120000;

	bool bActivated = false;

	float LifeTime = 10.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DestructibleRocksComp.OnDestructibleRockHit.AddUFunction(this, n"OnDestructibleRockHit");
	}

	UFUNCTION()
	private void OnDestructibleRockHit(USceneComponent HitComponent, AHazePlayerCharacter Player)
	{
		Player.DamagePlayerHealth(0.1);
		Player.PlayCameraShake(CameraShake, this);
		AddActorCollisionBlock(this);
		AddActorVisualsBlock(this);
		UStormCliffRockEventHandler::Trigger_OnRockDestroyed(this, FStormCliffRockParams(ActorLocation));
	}

	void ActivateCliffRock()
	{
		bActivated = true;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 10000.0, 25000.0);
		}
	}
};