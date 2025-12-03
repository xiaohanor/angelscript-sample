
UCLASS(Abstract)
class UGameplay_Vehicle_FlyingCar_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnTakeDamage(FSkylineFlyingCarDamage CarDamage){}

	UFUNCTION(BlueprintEvent)
	void OnSplineHopEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnSplineHopStart(){}

	UFUNCTION(BlueprintEvent)
	void OnCloseToEdgeEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnCloseToEdgeStart(){}

	UFUNCTION(BlueprintEvent)
	void OnTurretGunShot(FSkylineFlyingCarTurretGunshot TurretGunshot){}

	UFUNCTION(BlueprintEvent)
	void OnCollision(FSkylineFlyingCarCollision Collision){}

	UFUNCTION(BlueprintEvent)
	void OnDash(){}

	UFUNCTION(BlueprintEvent)
	void OnTurretProjectileHit(FSkylineFlyingCarTurretProjectileImpact TurretImpactData){}

	UFUNCTION(BlueprintEvent)
	void OnTurretProjectileFlyby(FSkylineFlyingCarTurretProjectileFlyby FlybyData){}

	UFUNCTION(BlueprintEvent)
	void OnStopGroundedMovement(){}

	UFUNCTION(BlueprintEvent)
	void OnStartGroundedMovement(){}

	UFUNCTION(BlueprintEvent)
	void OnCarExploded(){}

	UFUNCTION(BlueprintEvent)
	void OnCarEnterHighway(){}

	UFUNCTION(BlueprintEvent)
	void OnCarExitHighway(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	USkylineFlyingCarHealthComponent CarHealthComponent;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		CarHealthComponent = USkylineFlyingCarHealthComponent::Get(HazeOwner);
	}

}