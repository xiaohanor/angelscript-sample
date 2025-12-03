UCLASS(Abstract)
class ASummitKnightCrystalCore : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent AttackComp;

	UPROPERTY(EditAnywhere)
	AStaticCameraActor CutCamera;

	FVector TileStartLocation;

	UPROPERTY()
	int PhaseTicker;

	UPROPERTY()
	int AttackSwitcher;

	UPROPERTY()
	TArray<ASummitKnightFallingPlatforms> AllFallingTiles;

	UPROPERTY()
	TArray<ASummitKnightCrystalPlatform> AllCrystalPlatforms;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASummitKnightCrystalObstacle> WallClass;

	UPROPERTY(EditInstanceOnly)
	ASummitKnightSeekerMissileTurret FireballTurretTemp;

	UPROPERTY(EditInstanceOnly)
	ASummitKnightSeekerMissileTurret BigFireballTurretTemp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TileStartLocation = MeshRoot.RelativeLocation;

		AllFallingTiles = TListedActors<ASummitKnightFallingPlatforms>().GetArray();	

		AllCrystalPlatforms = TListedActors<ASummitKnightCrystalPlatform>().GetArray();

		AttackComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	float HitByRollCooldownTime = 0;

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (Time::GameTimeSeconds < HitByRollCooldownTime)
			return;
		HitByRollCooldownTime = Time::GameTimeSeconds + 5.0;

		PhaseTicker++;
		PhaseChecker();
	}

	
	void PhaseChecker()
	{
		BP_PhaseChecker();
	}

	UFUNCTION(BlueprintEvent)
	void BP_PhaseChecker()
	{

	}

	UFUNCTION()
	void SpawnWall()
	{
	}

	UFUNCTION()
	void ShootFireball()
	{
	}

	UFUNCTION()
	void ShootLargeFireball()
	{
	}


	void SetPendingPhaseTick(float Delay)
	{
		bHasPendingPhaseTick = true;
		PhaseTickerDelayTime = Time::GameTimeSeconds + Delay;
	}

	void IncreasePhaseTick()
	{
		PhaseTicker++;
	}


	bool bHasPendingPhaseTick = false;
	float PhaseTickerDelayTime = 0;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bHasPendingPhaseTick && (Time::GameTimeSeconds > PhaseTickerDelayTime))
		{
			IncreasePhaseTick();
			bHasPendingPhaseTick = false;
		}
	}
};