class UIslandBeamTurretronTrackingLaserComponent : UActorComponent
{
	UPROPERTY()
	FIslandBeamTurretronTrackingLaserParams TrackingLaserParams;
}

struct FIslandBeamTurretronTrackingLaserParams
{
	UPROPERTY()
	FVector LaserStartLocation;

	UPROPERTY()
	FVector LaserEndLocation;
}