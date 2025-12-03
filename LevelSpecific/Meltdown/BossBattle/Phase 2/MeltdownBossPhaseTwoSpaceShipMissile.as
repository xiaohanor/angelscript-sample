class AMeltdownBossPhaseTwoSpaceShipMissile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LaserMissile;

	float Speed = 8000;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDamageEffect> ProjectileHit;
	AMeltdownBossPhaseTwoSpaceShip Spaceship;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UMeltdownBossPhaseTwoSpaceShipMissileEffectHandler::Trigger_Spawn(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Velocity = ActorForwardVector * Speed;
		FVector DeltaMove = Velocity * DeltaSeconds;
		MoveMissile(DeltaMove);
	}

	void MoveMissile(FVector DeltaMove)
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);

		auto HitResult = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMove);

		if (HitResult.bBlockingHit)
		{
			PlayerHealth::DamagePlayersInRadius(ActorLocation, 200, 0.5, DamageEffect = ProjectileHit);

			ActorLocation = HitResult.Location;

			FMeltdownBossPhaseTwoSpaceShipMissileImpactParams ImpactParams;
			ImpactParams.ImpactLocation = HitResult.ImpactPoint;
			UMeltdownBossPhaseTwoSpaceShipMissileEffectHandler::Trigger_Impact(this, ImpactParams);

			FMeltdownBossPhaseTwoSpaceShipShotImpactParams ShotImpactParams;
			ShotImpactParams.ImpactLocation = HitResult.ImpactPoint;
			ShotImpactParams.ImpactNormal = HitResult.ImpactNormal;
			ShotImpactParams.MuzzleLocation = Spaceship.MissileSpawn.WorldLocation;;
			UMeltdownBossPhaseTwoSpaceShipEffectHandler::Trigger_ShotImpact(Spaceship, ShotImpactParams);

			DestroyActor();
			return;
		}

		ActorLocation += DeltaMove;
	}
};

struct FMeltdownBossPhaseTwoSpaceShipMissileImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;
}

UCLASS(Abstract)
class UMeltdownBossPhaseTwoSpaceShipMissileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawn() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact(FMeltdownBossPhaseTwoSpaceShipMissileImpactParams ImpactParams) {}
}