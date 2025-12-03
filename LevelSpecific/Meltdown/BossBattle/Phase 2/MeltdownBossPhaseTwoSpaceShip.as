event void fOnRunComplete();

class AMeltdownBossPhaseTwoSpaceShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBillboardComponent MissileSpawn;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBillboardComponent RightMissileSpawn;

	UPROPERTY(DefaultComponent)
	UMeltdownBossObjectFadeComponent ObjectFade;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseTwoSpaceShipMissile> Missile;

	UPROPERTY()
	FVector StartLocation;

	FVector TargetLoc;

	FVector MissileSpawnLocation;

	AHazePlayerCharacter TargetPlayer;
	private FVector OriginalLaunchDirection;

	float FireRate = 0.1;

	UPROPERTY()
	float TurnRate = 10.0;

	float TimeToFire;

	float SplineStart;

	float CurrentSplineDistance;

	float Timer = 0.0;
	float LifeTime = 14.0;

	float Speed = 1500;

	UPROPERTY()
	fOnRunComplete RunComplete;

	UPROPERTY()
	bool bCanfire;

	UPROPERTY()
	bool bIsOnGround;

	bool bLaunched = false;
	AMeltdownBossPhaseTwo Rader;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = MeshRoot.WorldLocation;
		AddActorDisable(this);

		UMeltdownBossPhaseTwoSpaceShipEffectHandler::Trigger_Spawn(this);
	}

	UFUNCTION(BlueprintCallable)
	void LaunchSpaceShip()
	{	
		RemoveActorDisable(this);
		bLaunched = true;

		OriginalLaunchDirection = (TargetPlayer.ActorLocation - ActorLocation).GetSafeNormal2D();
		ActorRotation = FRotator::MakeFromX(OriginalLaunchDirection);

		UMeltdownBossPhaseTwoSpaceShipEffectHandler::Trigger_Throw(this);
		
		ObjectFade.FadeIn();
	}

	UFUNCTION()
	void StartFiring()
	{	
		bCanfire = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bLaunched)
			return;

		if (Rader != nullptr && Rader.IsDead())
		{
			AddActorDisable(n"RaderDead");
			return;
		}

		FVector TargetVector = (TargetPlayer.ActorLocation - ActorLocation).GetSafeNormal2D();
		if (TargetVector.DotProduct(OriginalLaunchDirection) > 0)
		{
			ActorRotation = Math::RInterpConstantShortestPathTo(
				ActorRotation,
				FRotator::MakeFromX(TargetVector),
				DeltaSeconds,
				TurnRate,
			);
		}

		FVector NewLocation = ActorLocation;
		float CurrentSpeed = Math::GetMappedRangeValueClamped(
			FVector2D(0.0, 2.0),
			FVector2D(4000.0, Speed),
			Timer
		);

		NewLocation += ActorForwardVector * CurrentSpeed * DeltaSeconds;

		if (Timer < 2.0)
		{
			float LoweringSpeed = Math::GetMappedRangeValueClamped(
				FVector2D(0.0, 2.0),
				FVector2D(1600.0, 0.0),
				Timer
			);

			NewLocation.Z += -LoweringSpeed * DeltaSeconds;
		}

		SetActorLocation(NewLocation);
		SetActorScale3D(FVector(
			Math::GetMappedRangeValueClamped(
				FVector2D(0.0, 1.0),
				FVector2D(0.01, 1.0),
				Timer
			)
		));

		if (Timer > (LifeTime-1))
		{
			if(!bStartedFade)
			{
				bStartedFade = true;
				ObjectFade.FadeOut();
			}
		}

		Timer += DeltaSeconds;
		if (Timer > LifeTime)
		{
			UMeltdownBossPhaseTwoSpaceShipEffectHandler::Trigger_Despawn(this);
			DestroyActor();
			ActorLocation = StartLocation;
		}

		if (TimeToFire <= Time::GameTimeSeconds)
		{
			if (bCanfire == true)
			{
				TimeToFire = Time::GameTimeSeconds + FireRate;
				ShootLeftMissile();
		//		ShootRightMissile();
			}
		}
	}
	
	bool bStartedFade = false;

	UFUNCTION(BlueprintCallable)
	void RunOver()
	{
		RunComplete.Broadcast();
		DestroyActor();
	}

	UFUNCTION(BlueprintCallable)
	void ShootLeftMissile()
	{
		MissileSpawnLocation = MissileSpawn.WorldLocation;

		FMeltdownBossPhaseTwoSpaceShipShootParams ShootParams;
		ShootParams.MuzzleLocation = MissileSpawnLocation;
		UMeltdownBossPhaseTwoSpaceShipEffectHandler::Trigger_Shoot(this, ShootParams);

		AMeltdownBossPhaseTwoSpaceShipMissile MissileSpawned = Cast<AMeltdownBossPhaseTwoSpaceShipMissile> (SpawnActor(Missile, MissileSpawnLocation, MissileSpawn.WorldRotation, bDeferredSpawn = true));
		MissileSpawned.Spaceship = this;
		FinishSpawningActor(MissileSpawned);
	}

	UFUNCTION(BlueprintCallable)
	void ShootRightMissile()
	{
		MissileSpawnLocation = RightMissileSpawn.WorldLocation;

		FMeltdownBossPhaseTwoSpaceShipShootParams ShootParams;
		ShootParams.MuzzleLocation = MissileSpawnLocation;
		UMeltdownBossPhaseTwoSpaceShipEffectHandler::Trigger_Shoot(this, ShootParams);

		AMeltdownBossPhaseTwoSpaceShipMissile MissileSpawned = Cast<AMeltdownBossPhaseTwoSpaceShipMissile> (SpawnActor(Missile, MissileSpawnLocation, RightMissileSpawn.WorldRotation, bDeferredSpawn = true));
		FinishSpawningActor(MissileSpawned);
	}
};

struct FMeltdownBossPhaseTwoSpaceShipShootParams
{
	UPROPERTY()
	FVector MuzzleLocation;
}

struct FMeltdownBossPhaseTwoSpaceShipShotImpactParams
{
	UPROPERTY()
	FVector MuzzleLocation;

	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FVector ImpactNormal;
}


UCLASS(Abstract)
class UMeltdownBossPhaseTwoSpaceShipEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawn() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Throw() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Shoot(FMeltdownBossPhaseTwoSpaceShipShootParams ShootParams) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ShotImpact(FMeltdownBossPhaseTwoSpaceShipShotImpactParams ShotImpactarams) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Despawn() {}
}