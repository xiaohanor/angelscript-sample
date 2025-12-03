UCLASS(hideCategories="Camera Rendering Cooking Input Actor LOD AssetUserData Debug Collision InternalHiddenObjects", Meta = (HighlightPlacement))
class ABallSocketCameraActor : AHazeCameraActor
{
	UPROPERTY(OverrideComponent = Camera, ShowOnActor)
	UBallSocketCamera Camera;

	UPROPERTY(EditAnywhere, Category = "Current Camera Settings|Ball Socket Camera")
	float BallSocketRotationSpeed = -1.0;


	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		auto BallSocketData = Cast<UCameraBallSocketUpdater>(CameraData);
		BallSocketData.RotationSpeed = BallSocketRotationSpeed;
	}

	
};
