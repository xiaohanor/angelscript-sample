class UIslandAttackShipTrackingLaserComponent : UActorComponent
{
	UPROPERTY()
	FIslandAttackShipTrackingLaserParams TrackingLaserParams;
}

struct FIslandAttackShipTrackingLaserParams
{
	UPROPERTY()
	FVector LaserStartLocation;

	UPROPERTY()
	FVector LaserEndLocation;
}