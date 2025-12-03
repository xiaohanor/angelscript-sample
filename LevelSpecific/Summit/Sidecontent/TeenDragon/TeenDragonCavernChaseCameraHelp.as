class ATeenDragonCavernChaseCameraHelp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent Visuals;
	default Visuals.SetWorldScale3D(FVector(10.0));
#endif

	UFUNCTION()
	void DoBullshit(AHazeCameraActor CameraIGuess, AHazePlayerCharacter PlayerISuppose)
	{
		auto UserComp = UCameraUserComponent::Get(PlayerISuppose);
		PlayerISuppose.SnapCameraBehindPlayer();

		CameraIGuess.ActorLocation = UserComp.GetDefaultCameraView(false).Location;
		
		if (PlayerISuppose.IsMio())
		{

			CameraIGuess.ActorLocation -= FVector::UpVector * 140.0;
		}
		else
		{
			CameraIGuess.ActorLocation -= FVector::UpVector * 30.0;
			CameraIGuess.ActorLocation += -CameraIGuess.ActorForwardVector * 40.0;
		}	
		
		CameraIGuess.ActorRotation = UserComp.GetDefaultCameraView(false).Rotation;
	}
};