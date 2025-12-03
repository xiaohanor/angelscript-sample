event void FDroneButtonMashInteractionStartedEvent();
event void FDroneButtonMashInteractionStoppedEvent();
event void FDroneButtonMashInteractionCompletedEvent();

UCLASS(Abstract)
class ADroneButtonMashInteractionActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent DroneAttachComp;

	UPROPERTY(DefaultComponent)
	USceneComponent WidgetAttachComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FDroneButtonMashInteractionSettings MashSettings;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY()
	FDroneButtonMashInteractionStartedEvent OnButtonMashStarted;

	UPROPERTY()
	FDroneButtonMashInteractionStoppedEvent OnButtonMashStopped;

	UPROPERTY()
	FDroneButtonMashInteractionCompletedEvent OnButtonMashCompleted;

	UPROPERTY(EditAnywhere)
	ADroneButtonMashInteractionActor LinkedInteractionActor;

	float CurrentProgress = 0.0;
	
	bool bInteractionCompleted = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (LinkedInteractionActor != nullptr)
			MashSettings.bCanBeCompleted = false;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"InteractionStopped");
	}

	UFUNCTION()
	private void InteractionStarted(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		auto PlayerComp = UDroneButtonMashInteractionPlayerComponent::Get(Player);
		PlayerComp.CurrentInteractionActor = this;

		CapabilityRequestComp.StartInitialSheetsAndCapabilities(Player, this);

		OnButtonMashStarted.Broadcast();
	}

	UFUNCTION()
	private void InteractionStopped(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		CapabilityRequestComp.StopInitialSheetsAndCapabilities(Player, this);

		OnButtonMashStopped.Broadcast();
	}

	void InteractionCompleted(AHazePlayerCharacter Player)
	{
		if (bInteractionCompleted)
			return;

		bInteractionCompleted = true;
		InteractionComp.Disable(this);

		InteractionComp.KickAnyPlayerOutOfInteraction();

		OnButtonMashCompleted.Broadcast();
	}
}

struct FDroneButtonMashInteractionSettings
{
	UPROPERTY()
	float Duration = 4.0;

	UPROPERTY()
	EButtonMashDifficulty Difficulty = EButtonMashDifficulty::Medium;

	UPROPERTY()
	bool bCanBeCompleted = true;
}