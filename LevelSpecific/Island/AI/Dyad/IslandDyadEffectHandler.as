UCLASS(Abstract)
class UIslandDyadEffectHandler : UHazeEffectEventHandler
{

	// The owner died
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartedLaser(FIslandDyadAimingEventData Data) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStoppedLaser() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLaserHit(FIslandDyadLaserHitEventData Data) {}
}

struct FIslandDyadAimingEventData
{
	FIslandDyadAimingEventData(UIslandDyadLaserComponent InAimingComp)
	{
		AimingComponent = InAimingComp;
	}

	UPROPERTY(BlueprintReadOnly)
	UIslandDyadLaserComponent AimingComponent;
}

struct FIslandDyadLaserHitEventData
{
	FIslandDyadLaserHitEventData(FVector InHitLocation)
	{
		HitLocation = InHitLocation;
	}

	UPROPERTY(BlueprintReadOnly)
	FVector HitLocation;
}