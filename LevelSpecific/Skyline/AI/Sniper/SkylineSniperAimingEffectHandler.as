UCLASS(Abstract)
class USkylineSniperAimingEffectHandler : UHazeEffectEventHandler
{

	// Sniper started aiming (SkylineSniperAiming.OnStartedAiming)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedAiming(FSkylineSniperAimingEventData EventData) {}

	// Sniper decided where to shoot and stopped changing its aiming (SkylineSniperAiming.OnDecidedAiming)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDecidedAiming(FSkylineSniperAimingEventData EventData) {}

	// Sniper stopped aiming (SkylineSniperAiming.OnStoppedAiming)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedAiming(FSkylineSniperAimingEventData EventData) {}
}

struct FSkylineSniperAimingEventData
{
	UPROPERTY(BlueprintReadOnly)
	USkylineSniperAimingComponent AimingComponent;
}