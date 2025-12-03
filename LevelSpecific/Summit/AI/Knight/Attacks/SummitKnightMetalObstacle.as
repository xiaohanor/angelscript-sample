asset KnightMetalObstacleMeltSettings of USummitMeltSettings
{
	MaxHealth = 0.1;
	DissolveDuration = 0.5;
	StayMeltedDuration = 3.0;
	StayDissolvedDuration = BIG_NUMBER;
	RestoreDuration = 1.0;
}

UCLASS(Abstract)
class ASummitKnightMetalObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = "MeshRoot")
	USummitMeltPartComponent Mesh0;
	default Mesh0.CollisionProfileName = n"BlockOnlyProjectiles";

	UPROPERTY(DefaultComponent, Attach = "MeshRoot")
	USummitMeltPartComponent Mesh1;
	default Mesh0.CollisionProfileName = n"BlockOnlyProjectiles";

	UPROPERTY(DefaultComponent, Attach = "MeshRoot")
	USummitMeltPartComponent Mesh2;
	default Mesh0.CollisionProfileName = n"BlockOnlyProjectiles";

	UPROPERTY(DefaultComponent, Attach = "MeshRoot")
	USummitMeltPartComponent Mesh3;
	default Mesh0.CollisionProfileName = n"BlockOnlyProjectiles";

	UPROPERTY(DefaultComponent, Attach = "MeshRoot")
	USummitMeltPartComponent Mesh4;
	default Mesh0.CollisionProfileName = n"BlockOnlyProjectiles";

	UPROPERTY(DefaultComponent, Attach = "MeshRoot")
	USummitMeltPartComponent Mesh5;
	default Mesh0.CollisionProfileName = n"BlockOnlyProjectiles";

	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent Collision;
	default Collision.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AcidAimComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"AISummitMeltCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditDefaultsOnly)
	TArray<UStaticMesh> MeshVariants;

	UPROPERTY(EditInstanceOnly)
	bool bIsLevelPlaceable = false;

	bool bSpawned = false;
	bool bVisible = false;
	bool bCollision = false;
	float UnspawnTime = BIG_NUMBER;

	FHazeAcceleratedFloat AccScale;
	FVector DefaultScale;

	TArray<UStaticMeshComponent> Meshes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(Meshes);
		Meshes.Shuffle();
		if (MeshVariants.Num() == 0)
			MeshVariants.Add(Mesh0.StaticMesh);

		if(!bIsLevelPlaceable)
		{
			AddActorDisable(this);
			MeshRoot.AddComponentVisualsBlocker(this);
			for (UStaticMeshComponent Mesh : Meshes)
			{
				Mesh.AddComponentVisualsBlocker(this);
			}
			AddActorCollisionBlock(this);
		}

		MeltComp.OnMelted.AddUFunction(this, n"OnMelted");
		DefaultScale = MeshRoot.WorldScale;
	}

	void SpawnObstacle(int iVariant, AHazeActor Knight)
	{
		if (bSpawned)
			return;

		UHazeComposableSettings MeltSettings = USummitKnightSettings::GetSettings(Knight).MetalObstacleMeltSettings;
		ApplySettings(MeltSettings, Knight);

		// In very rare cases when too many obstacles are spawned we can get an invalid index here 
		int iVar = iVariant % MeshVariants.Num();
		if (!MeshVariants.IsValidIndex(iVar))
			iVar = (iVar % MeshVariants.Num()) + MeshVariants.Num();

		for (int i = 0; i < Meshes.Num(); i++)
		{
			Meshes[i].SetStaticMesh(MeshVariants[(iVar + i) % MeshVariants.Num()]);
		}

		// Start small and grow up
		AccScale.SnapTo(0.01);
		MeshRoot.WorldScale3D = DefaultScale * AccScale.Value;

		// Random yaw, slight variation in pitch/roll
		FRotator Rot;
		Rot.Yaw = Math::RandRange(-180.0, 180.0);
		Rot.Pitch = Math::RandRange(-10.0, 10.0);
		Rot.Roll = Math::RandRange(-10.0, 10.0);
		ActorRotation = Rot;	

		bSpawned = true;
		RemoveActorDisable(this);
		MeltComp.ImmediateRestore();
		MeltComp.OnReset();
		
		if (!bVisible)
		{
			MeshRoot.RemoveComponentVisualsBlocker(this);
			for (UStaticMeshComponent Mesh : Meshes)
			{
				Mesh.RemoveComponentVisualsBlocker(this);
			}
		}
		if (!bCollision)
			RemoveActorCollisionBlock(this);
		bVisible = true;
		bCollision = true;
		UnspawnTime = BIG_NUMBER;

		USummitKnightMetalObstacleEventHandler::Trigger_OnSpawn(this);
	}

	UFUNCTION()
	private void OnMelted()
	{
		StartUnspawning();
		USummitKnightMetalObstacleEventHandler::Trigger_OnFullyMelted(this);
	}

	void Shatter()
	{
		StartUnspawning();
		USummitKnightMetalObstacleEventHandler::Trigger_OnShatter(this);
	}

	void StartUnspawning()
	{
		// Hide and turn off collision now, but disable only after effects have had time to deactivate
		UnspawnTime = Time::GameTimeSeconds + 5.0;
		if (bVisible)
		{
			MeshRoot.AddComponentVisualsBlocker(this);
			for (UStaticMeshComponent Mesh : Meshes)
			{
				Mesh.AddComponentVisualsBlocker(this);
			}
		}
		if (bCollision)
			AddActorCollisionBlock(this);
		bVisible = false;
		bCollision = false;
	}

	void Unspawn()
	{
		if (!bSpawned)
			return;

		bSpawned = false;
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (AccScale.Value < 0.999)
		{
			AccScale.AccelerateTo(1.0, 0.8, DeltaTime);
			MeshRoot.WorldScale3D = DefaultScale * AccScale.Value;
		}

		if (Time::GameTimeSeconds > UnspawnTime)
			Unspawn();	
	}

	bool IsActive() const
	{
		if (!bSpawned)
			return false;
		if (!bCollision)
			return false;
		return true;
	}
};

UCLASS(Abstract)
class USummitKnightMetalObstacleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawn(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShatter() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyMelted() {}
}
