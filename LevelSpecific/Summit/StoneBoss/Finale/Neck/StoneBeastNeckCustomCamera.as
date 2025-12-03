class AStoneBeastNeckCustomCamera : AHazeCameraActor
{
	UPROPERTY(OverrideComponent = Camera, ShowOnActor)
	UHazeCameraComponent Camera;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StoneBeastNeckCustomCameraCapability");
};