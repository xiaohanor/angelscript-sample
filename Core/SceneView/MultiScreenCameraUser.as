class AMultiScreenCameraUser : AHazeAdditionalCameraUser
{
	UPROPERTY(DefaultComponent, Attach = "Root", ShowOnActor, Category = "Camera")
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent)
	UHazeCameraUserComponent CameraUserComp;	
};