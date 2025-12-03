UCLASS(HideCategories = "Rendering Physics Collision Lighting Navigation Debug Activation Cooking LOD HLOD TextureStreaming RayTracing Actor Tags")
class ACoastTrainCameraBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeLazyPlayerOverlapComponent Box;
	default Box.Shape.InitializeAsBox(FVector(100.0, 100.0, 100.0));
	// default Box.DrawLineThickness = 0.0;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeCameraSettingsComponent CameraSettings;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Box.OnPlayerBeginOverlap.AddUFunction(this, n"OnPlayerEnter");
		Box.OnPlayerEndOverlap.AddUFunction(this, n"OnPlayerExit");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		CameraSettings.Apply(UHazeCameraUserComponent::Get(Player));
	}

	UFUNCTION()
	private void OnPlayerExit(AHazePlayerCharacter Player)
	{
		CameraSettings.Clear(UHazeCameraUserComponent::Get(Player));
	}
};