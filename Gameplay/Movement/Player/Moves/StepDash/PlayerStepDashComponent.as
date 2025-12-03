
class UPlayerStepDashComponent : UActorComponent
{
	UPROPERTY()
	UPlayerStepDashSettings Settings;	
	UPROPERTY()
	UForceFeedbackEffect DashChainForceFeedback;
	UPROPERTY()
	UForceFeedbackEffect DashDefaultForceFeedback;

	UPROPERTY()
	EStepDashDirection StepDirection;

	AHazePlayerCharacter Player;
	//float LastStepDashActivation = -1000.0;
	bool bHasRolled = false;
	float CombinedDashCooldown = 0.0;

	private bool bIsDashingInternal = false;
	private float LastStepDashActivationInternal = -1000.0;
	int ChainedDashCount = 0;

	bool bTEMP_CameraAmplification = false;

	FVector2D BS_Strafe_Direction = FVector2D::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerStepDashSettings::GetSettings(Cast<AHazeActor>(Owner));
		Player = Cast<AHazePlayerCharacter>(Owner);

		FHazeDevInputInfo DevInput;
		DevInput.Name = n"Dash Camera Amplification";
		DevInput.Category = n"Movement";
		DevInput.AddAction(ActionNames::Interaction);
		DevInput.OnTriggered.BindUFunction(this, n"OnToggleCameraAmplification");
		DevInput.OnStatus.BindUFunction(this, n"OnCameraAmplificationStatus");
		Player.RegisterDevInput(DevInput);
	}

	UFUNCTION()
	private void OnCameraAmplificationStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		if (bTEMP_CameraAmplification)
		{
			OutDescription = "[ ON ]";
			OutColor = FLinearColor::Green;
		}
		else
		{
			OutDescription = "[ OFF ]";
			OutColor = FLinearColor::Red;
		}
	}

	UFUNCTION()
	private void OnToggleCameraAmplification()
	{
		bTEMP_CameraAmplification = !bTEMP_CameraAmplification;
	}

	void StartDash()
	{
		bIsDashingInternal = true;
		LastStepDashActivationInternal = Time::GameTimeSeconds;
	}

	void StopDash()
	{
		bIsDashingInternal = false;
	}

	bool IsDashing() const
	{
		return bIsDashingInternal;
	}

	float GetLastStepDashActivation() const property
	{
		return LastStepDashActivationInternal;
	}
}