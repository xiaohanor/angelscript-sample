UCLASS(Abstract)
class ASummitKnightCrystalObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent Collision;
	default Collision.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	default TailAttackResponseComp.ImpactType = ETailAttackImpactType::Enemy;
	default TailAttackResponseComp.bIsPrimitiveParentExclusive = false;
	default TailAttackResponseComp.bShouldStopPlayer = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditDefaultsOnly)
	TArray<UStaticMesh> MeshVariants;

	bool bSpawned = false;
	bool bVisible = false;
	bool bCollision = false;
	float UnspawnTime = BIG_NUMBER;

	FHazeAcceleratedFloat AccScale;
	FVector DefaultScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		Mesh.AddComponentVisualsBlocker(this);
		AddActorCollisionBlock(this);
		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		DefaultScale = Mesh.WorldScale;

		if (MeshVariants.Num() == 0)
			MeshVariants.Add(Mesh.StaticMesh);
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!bCollision)
			return;

		Shatter();
	}

	void SpawnObstacle(int iVariant)
	{
		if (bSpawned)
			return;

		// In very rare cases when too many obstacles are spawned we can get an invalid index here 
		int iVar = iVariant % MeshVariants.Num();
		if (!MeshVariants.IsValidIndex(iVar))
			iVar = ((iVar % MeshVariants.Num()) + MeshVariants.Num()) % MeshVariants.Num();

		if (MeshVariants[iVar] != nullptr)			
			Mesh.SetStaticMesh(MeshVariants[iVar]);	

		// Random yaw, slight variation in pitch/roll
		FRotator Rot;
		Rot.Yaw = Math::RandRange(-180.0, 180.0);
		Rot.Pitch = Math::RandRange(-15.0, 15.0);
		Rot.Roll = Math::RandRange(-15.0, 15.0);
		ActorRotation = Rot;	

		// Start small and grow up
		AccScale.SnapTo(0.01);
		Mesh.WorldScale3D = DefaultScale * AccScale.Value;

		bSpawned = true;
		RemoveActorDisable(this);
		
		if (!bVisible)
			Mesh.RemoveComponentVisualsBlocker(this);
		if (!bCollision)
			RemoveActorCollisionBlock(this);
		bVisible = true;
		bCollision = true;

		USummitKnightCrystalObstacleEventHandler::Trigger_OnSpawn(this);
	}

	void Shatter()
	{
		StartUnspawning();
		USummitKnightCrystalObstacleEventHandler::Trigger_OnShatter(this);
	}

	void StartUnspawning()
	{
		// Hide and turn off collision now, but disable only after effects have had time to deactivate
		UnspawnTime = Time::GameTimeSeconds + 5.0;
		if (bVisible)
			Mesh.AddComponentVisualsBlocker(this);
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
			Mesh.WorldScale3D = DefaultScale * AccScale.Value;
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
class USummitKnightCrystalObstacleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawn(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShatter() {}
}
