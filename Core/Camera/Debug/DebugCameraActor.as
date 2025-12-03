class ADebugCameraActor : AHazeCameraActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(OverrideComponent = Camera, ShowOnActor)
	UHazeCameraComponent Camera;
	default Camera.FieldOfView = 70.0;
	
	// This is a debug camera and will override the debug view
	default Camera.bApplyDebugView = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedLocation;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotation;

	UPROPERTY(Category = "Debug Camera")
	float BaseSpeed = 2000.0;
	
	UPROPERTY(Category = "Debug Camera")
	float MaxHoldSpeedFactor = 5.0;

	UPROPERTY(Category = "Debug Camera")
	FRotator TurnRate = FRotator(180.0, 360.0, 0.0);
}

