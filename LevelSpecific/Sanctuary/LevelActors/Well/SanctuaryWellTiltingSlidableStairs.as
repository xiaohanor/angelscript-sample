class ASanctuaryWellTiltingSlidableStairs : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(EditInstanceOnly)
	APlayerForceSlideVolume SlideVolumeActor;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraVolume CameraVolumeActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void Activate()
	{
		RotateComp.ConstrainAngleMax = 10.0;
		SlideVolumeActor.SetVolumeEnabled(true);
		//CameraVolumeActor.Enable();
	}
};