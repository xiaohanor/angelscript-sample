struct FPirateShipHitWaveEventData
{
	UPROPERTY()
	float ForwardSpeed;

	UPROPERTY()
	float HullNormalSpeed;

	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FRotator Rotation;
}

UCLASS(Abstract)
class UPirateShipEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	APirateShip Ship;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ship = Cast<APirateShip>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitWave(FPirateShipHitWaveEventData EventData)
	{
	}
};