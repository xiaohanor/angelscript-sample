USTRUCT()
struct FSkylineFlyingCarTurretGunshot
{
	UPROPERTY()
	FVector Origin;

	UPROPERTY()
	FVector Target;

	UPROPERTY()
	FVector ImpactNormal;

	UPROPERTY()
	float TravelTime;

	UPROPERTY()
	float OverheatAmount;

}

USTRUCT()
struct FSkylineFlyingCarTurretProjectileImpact
{
	UPROPERTY()
	AHazeActor HitActor = nullptr;

	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FVector ImpactNormal;

	UPROPERTY()
	UPhysicalMaterial ImpactPhysMat = nullptr;
}

USTRUCT()
struct FSkylineFlyingCarBazookaImpact
{
	UPROPERTY()
	FVector Origin;

	UPROPERTY()
	FVector Target;

	UPROPERTY()
	FVector ImpactNormal;

}

USTRUCT()
struct FSkylineFlyingCarTurretProjectileFlyby
{
	UPROPERTY()
	float FlybyDistanceNormalized = 0.0;

	// -1 to 1, -1 = Max distance left side, 1 = Max distance right side
	UPROPERTY()
	float FlybyDistanceSigned = 0.0;
}

class USkylineFlyingCarEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	ASkylineFlyingCar FlyingCarOwner;

	bool bSplineHopping = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlyingCarOwner = Cast<ASkylineFlyingCar>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDash() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCollision(FSkylineFlyingCarCollision Collision) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTurretGunShot(FSkylineFlyingCarTurretGunshot TurretGunshot) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTurretProjectileHit(FSkylineFlyingCarTurretProjectileImpact TurretImpactData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTurretProjectileFlyby(FSkylineFlyingCarTurretProjectileFlyby FlybyData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBazookaShot() { }


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRifleReload() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBazookaReload() { }


	// Car just got close to the edge and can jump to another tunnel
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCloseToEdgeStart() { }

	// Car is no longer close to edge
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCloseToEdgeEnd() { }

	UFUNCTION(BlueprintPure)
	bool IsCloseToEdge() { return FlyingCarOwner.IsCloseToSplineEdge(); }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCarEnterHighway() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCarExitHighway() {}

	// Car is jumping away from spline tunnel
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSplineHopStart() { }

	// Car just landed after jumping from spline
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSplineHopEnd() { }

	UFUNCTION(BlueprintPure)
	bool IsSplineHopping() { return FlyingCarOwner.bJustSplineHopped; }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTakeDamage(FSkylineFlyingCarDamage CarDamage) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCarExploded() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartGroundedMovement() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopGroundedMovement() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRampBoostStart() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRampBoostEnd() { }
}