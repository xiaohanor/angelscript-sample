class USkylineFlyingCarEnemyTrackingLaserComponent : UActorComponent
{
	UPROPERTY()
	FSkylineFlyingCarEnemyTrackingLaserParams TrackingLaserParams;
}

struct FSkylineFlyingCarEnemyTrackingLaserParams
{
	UPROPERTY()
	FVector LaserStartLocation;

	UPROPERTY()
	FVector LaserEndLocation;
}