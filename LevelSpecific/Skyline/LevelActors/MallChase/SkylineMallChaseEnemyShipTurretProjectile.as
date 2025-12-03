class ASkylineMallChaseEnemyShipTurretProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	float Speed = 12000.0;

	UPROPERTY(EditAnywhere)
	float Damage = 0.1;

	UPROPERTY(EditAnywhere)
	float DamageRadius = 300.0;

	AActor Instigator;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector DeltaMove = ActorForwardVector * Speed * DeltaSeconds;
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		if (IsValid(Instigator))
			Trace.IgnoreActor(Instigator);
		FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMove);
		AddActorWorldOffset(DeltaMove);

		if (Hit.bBlockingHit) {
//			PrintToScreen("HIT!" + Hit.Actor, 1.0);
//			Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEffect, Hit.Location, ActorRotation);
			BP_OnImpact(Hit.ImpactNormal);

	
			FSkylineMallChaseEnemyShipTurretProjectileImpactParams Params;
			Params.ImpactLocation = Hit.Location;
			Params.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromHit(Hit, FHazeTraceSettings()).AudioAsset);
			Params.ImpactNormal = AudioSharedProjectiles::GetProjectileImpactAngle(ActorForwardVector, Hit.ImpactNormal);
			Params.ImpactNormalVector = Hit.ImpactNormal;
			if (IsValid(Instigator))
				USkylineMallChaseEnemyShipTurretProjectileEffectEventHandler::Trigger_ShotImpact(Cast<AHazeActor>(Instigator), Params);

		for (auto Player : Game::Players)
		{
			if (ActorLocation.Distance(Player.ActorLocation) < DamageRadius)
				Player.DamagePlayerHealth(Damage);
		}

			DestroyActor();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnImpact(FVector ImpactNormal) {}
}

struct FSkylineMallChaseEnemyShipTurretProjectileImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	UPhysicalMaterialAudioAsset AudioPhysMat;

	UPROPERTY()
	float ImpactNormal;

	UPROPERTY()
	FVector ImpactNormalVector;
}

UCLASS(Abstract)
class USkylineMallChaseEnemyShipTurretProjectileEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void ShotImpact(FSkylineMallChaseEnemyShipTurretProjectileImpactParams Params) {}
}