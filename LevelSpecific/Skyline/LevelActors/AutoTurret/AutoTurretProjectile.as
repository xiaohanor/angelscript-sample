class AAutoTurretProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	float Speed = 3000.0;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem HitEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector DeltaMove = ActorForwardVector * Speed * DeltaSeconds;
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMove);
		AddActorWorldOffset(DeltaMove);

		if (Hit.bBlockingHit) {
		//	PrintToScreen("HIT!", 1.0);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEffect, Hit.Location, ActorRotation);
			
			FAutoTurretProjectileImpactParams Params;
			Params.ImpactLocation = Hit.Location;
			Params.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromHit(Hit, FHazeTraceSettings()).AudioAsset);
			Params.ImpactNormal = AudioSharedProjectiles::GetProjectileImpactAngle(ActorForwardVector, Hit.ImpactNormal);
			UAutoTurretProjectileEffectEventHandler::Trigger_ShotImpact(this, Params);
			DestroyActor();
		}
	}

}

struct FAutoTurretProjectileImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	UPhysicalMaterialAudioAsset AudioPhysMat;

	UPROPERTY()
	float ImpactNormal;
}

UCLASS(Abstract)
class UAutoTurretProjectileEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void ShotImpact(FAutoTurretProjectileImpactParams Params) {}
}