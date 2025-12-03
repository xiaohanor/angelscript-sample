UCLASS(Abstract)
class UIslandBuzzerEffectHandler : UHazeEffectEventHandler
{

	// The owner died (IslandBuzzer.OnDeath)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath() {}

	// The owner died (IslandBuzzer.OnStartedLaser)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartedLaser(FIslandBuzzerAimingEventData Data) {}

	// The owner died (IslandBuzzer.OnStoppedLaser)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStoppedLaser() {}
}

struct FIslandBuzzerAimingEventData
{
	FIslandBuzzerAimingEventData(UIslandBuzzerLaserAimingComponent InAimingComp)
	{
		AimingComponent = InAimingComp;
	}

	UPROPERTY(BlueprintReadOnly)
	UIslandBuzzerLaserAimingComponent AimingComponent;
}