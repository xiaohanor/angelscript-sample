
struct FSniperTurretOnFireParams
{
	UPROPERTY()
	FVector MuzzleLocation;
	UPROPERTY()
	FRotator MuzzleRotation;
}

struct FSniperTurretOnHitParams
{
	UPROPERTY()
	UPrimitiveComponent Component;
	UPROPERTY()
	FVector RelativeHitImpactPoint;
	UPROPERTY()
	FVector RelativeHitImpactNormal;
	UPROPERTY()
	FVector TraceDirection;

	UPROPERTY()
	FHazeAudioTraceQuery AudioTraceParams;
	UPROPERTY()
	float NormalAngle;

	FSniperTurretOnHitParams(const FHitResult& Hit, const FHazeTraceSettings& TraceSettings, const FVector& ProjectileTravelDir)
	{
		Component = Hit.Component;
		RelativeHitImpactPoint = Component.GetWorldTransform().InverseTransformPosition(Hit.ImpactPoint);
		RelativeHitImpactNormal = Component.GetWorldTransform().InverseTransformVectorNoScale(Hit.ImpactNormal);
		TraceDirection = (Hit.TraceEnd - Hit.TraceStart).GetSafeNormal();

		AudioTraceParams = FHazeAudioTraceQuery(Hit, TraceSettings);
		NormalAngle = AudioSharedProjectiles::GetProjectileImpactAngle(-ProjectileTravelDir, Hit.ImpactNormal);
	}

	FVector GetImpactPoint() const
	{
		return Component.GetWorldTransform().TransformPosition(RelativeHitImpactPoint);
	}

	FVector GetImpactNormal() const
	{
		return Component.GetWorldTransform().TransformVectorNoScale(RelativeHitImpactNormal);
	}
}

USTRUCT()
struct FSniperTurretOnDrawLaserPointer
{
	UPROPERTY()
	FHitResult Hit;
	UPROPERTY()
	FTransform MuzzleWorldTransform;
}

/**
 * 
 */
 class UHackableSniperTurretEventHandler : UHazeEffectEventHandler
 {

	UPROPERTY()
	AHackableSniperTurret SniperTurret = nullptr;

	UPROPERTY()
	AHazePlayerCharacter Player = nullptr;

	UPROPERTY()
	UNiagaraSystem Sys_MuzzleFlash;

	UPROPERTY()
	UNiagaraSystem Sys_BulletImpact;

	UPROPERTY()
	UNiagaraSystem Sys_LaserPointer;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> FireCameraShakeClass;

	UPROPERTY()
	UForceFeedbackEffect FFA_Fire;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SniperTurret = Cast<AHackableSniperTurret>(Owner);
		Player = Drone::GetSwarmDronePlayer();
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeactivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnZoomActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnZoomDeactivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFire(FSniperTurretOnFireParams Params) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit(FSniperTurretOnHitParams Params) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDrawLaserPointer(FSniperTurretOnDrawLaserPointer Params) {}
 }