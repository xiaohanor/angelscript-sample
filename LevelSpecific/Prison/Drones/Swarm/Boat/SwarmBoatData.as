USTRUCT()
struct FSwarmBoatCameraSettings
{
	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset WaterMovementSettings;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset AirMovementSettings;
}

USTRUCT()
struct FSwarmBoatBoardingParams
{
	UPROPERTY()
	UForceFeedbackEffect BoardingFF;

	UPROPERTY()
	UForceFeedbackEffect DisembarkingFF;
}

struct FSwarmBoatBeachingParams
{
	FVector ExitImpluse = FVector::ZeroVector;
}

event void FSwarmBoatBoardingEvent();