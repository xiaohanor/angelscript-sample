UCLASS(Abstract)
class USkylineSniperTurretAimingEffectHandler : UHazeEffectEventHandler
{

	// SniperTurret started aiming (SkylineSniperAiming.OnStartedAiming)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedAiming(FSkylineSniperTurretAimingEventData EventData) {}

	// SniperTurret decided where to shoot and stopped changing its aiming (SkylineSniperTurretAiming.OnDecidedAiming)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDecidedAiming(FSkylineSniperTurretAimingEventData EventData) {}

	// SniperTurret stopped aiming (SkylineSniperAiming.OnStoppedAiming)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedAiming(FSkylineSniperTurretAimingEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShotFired() {}
}

struct FSkylineSniperTurretAimingEventData
{
	UPROPERTY(BlueprintReadOnly)
	USkylineSniperTurretAimingComponent AimingComponent;
}