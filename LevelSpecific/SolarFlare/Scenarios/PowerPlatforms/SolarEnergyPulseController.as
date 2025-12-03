class ASolarEnergyPulseController : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;

	UPROPERTY()
	UHazeCapabilitySheet CapabilitySheet;

	// UPROPERTY(EditAnywhere)
	// ASolarEnergyPulseSpline Spline1;
	// UPROPERTY(EditAnywhere)
	// ASolarEnergyPulseSpline Spline2;
	UPROPERTY(EditAnywhere)
	AStaticCameraActor Camera;

	UPROPERTY(EditAnywhere)
	TArray<ASolarEnergyRotationPlatform> LeftPlatforms;
	UPROPERTY(EditAnywhere)
	TArray<ASolarEnergyRotationPlatform> RightPlatforms;
	bool bActivateRight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
		SwapActivePlatforms();
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		UPlayerSolarEnergyPulseComponent UserComp = UPlayerSolarEnergyPulseComponent::Get(Player);
		UserComp.Controller = this;
		// UserComp.Spline1 = Spline1;
		// UserComp.Spline2 = Spline2;

		Player.ActivateCamera(Camera, 1.5, this, EHazeCameraPriority::High);
		Player.StartCapabilitySheet(CapabilitySheet, this);
		Interaction.Disable(this);
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Large);
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		Player.DeactivateCamera(Camera, 1.5);
		Player.StopCapabilitySheet(CapabilitySheet, this);
		Interaction.Enable(this);
		Player.ClearViewSizeOverride(this);
	}

	UFUNCTION()
	void SwapActivePlatforms()
	{
		if (bActivateRight)
		{
			for (ASolarEnergyRotationPlatform Platform : LeftPlatforms)
				Platform.SolarEnergyPulseStarted();
			for (ASolarEnergyRotationPlatform Platform : RightPlatforms)
				Platform.SolarEnergyPulseStopped();
		}
		else
		{
			for (ASolarEnergyRotationPlatform Platform : RightPlatforms)
				Platform.SolarEnergyPulseStarted();	
			for (ASolarEnergyRotationPlatform Platform : LeftPlatforms)
				Platform.SolarEnergyPulseStopped();		
		}

		bActivateRight = !bActivateRight;
	}
}