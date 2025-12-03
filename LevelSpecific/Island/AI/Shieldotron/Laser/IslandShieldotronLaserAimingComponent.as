class UIslandShieldotronLaserAimingComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly)
	FIslandShieldotronLaserAimingLocations AimingLocation;
}

struct FIslandShieldotronLaserAimingLocations
{
	UPROPERTY(BlueprintReadOnly)
	FVector StartLocation;
	UPROPERTY(BlueprintReadOnly)
	FVector EndLocation;
}