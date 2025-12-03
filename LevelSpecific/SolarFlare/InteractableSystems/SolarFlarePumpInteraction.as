event void FOnButtonMashApplied(float Progress);

class ASolarFlarePumpInteraction : AHazeActor
{
	UPROPERTY()
	FOnButtonMashApplied OnButtonMashApplied; 

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;

	UPROPERTY(EditAnywhere)
	AStaticCameraActor Camera;
	UPROPERTY(EditAnywhere)
	float BlendIn = 1.0;
	UPROPERTY(EditAnywhere)
	float BlendOut = 1.0;

	UButtonMashComponent ButtonMashComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		BlendCamera(true, Player);
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		BlendCamera(false, Player);
	}

	void BlendCamera(bool ShouldActivate, AHazePlayerCharacter Player)
	{
		if (Camera == nullptr)
			return;

		UCameraSettings CamSettings = UCameraSettings::GetSettings(Player);

		if (ShouldActivate)
		{
			Player.ActivateCamera(Camera, BlendIn, this);
			CamSettings.FOV.ApplyAsAdditive(-5, this, BlendIn);
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Large);
		}
		else
		{
			Player.DeactivateCamera(Camera, BlendOut);
			CamSettings.FOV.Clear(this, BlendOut);
			Player.ClearViewSizeOverride(this);
		}
	}
}