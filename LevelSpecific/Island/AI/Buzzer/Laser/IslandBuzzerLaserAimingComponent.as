class UIslandBuzzerLaserAimingComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly)
	FIslandBuzzerLaserAimingLocations AimingLocation;
}

struct FIslandBuzzerLaserAimingLocations
{
	UPROPERTY(BlueprintReadOnly)
	FVector StartLocation;
	UPROPERTY(BlueprintReadOnly)
	FVector EndLocation;
}