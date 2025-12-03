class ASolarFlareActivateCameraVolume : APlayerTrigger
{
	UPROPERTY(EditAnywhere)
	AStaticCameraActor Camera;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
		Player.ActivateCamera(Camera, 1.5, this);
	}
}