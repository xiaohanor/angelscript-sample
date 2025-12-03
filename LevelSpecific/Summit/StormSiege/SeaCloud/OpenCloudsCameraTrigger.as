class AOpenCloudsCameraTrigger : AActorTrigger
{
	UPROPERTY(EditAnywhere)
	UHazeCameraSpringArmSettingsDataAsset OpenCloudsCameraSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"OnActorEnter");
	}

	UFUNCTION()
	private void OnActorEnter(AHazeActor Actor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		Player.ApplyCameraSettings(OpenCloudsCameraSettings, 1.5, this, EHazeCameraPriority::Low);
	}
}