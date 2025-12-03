class UPlayerRollDashComponent : UActorComponent
{
	UPROPERTY()
	UPlayerRollDashSettings Settings;	
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> DashShake;
	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset DashCameraSetting;
	UPROPERTY()
	UForceFeedbackEffect DashForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect RollDashJumpFF;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> RollDashJumpCameraShake;

	private bool bDashingInternal = false;
	private float LastRollDashActivationInternal = - 1000.0;

	bool bTriggeredRollDashJump = false;
	
	FVector2D BS_Strafe_Direction = FVector2D::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerRollDashSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	void StartDash()
	{
		bDashingInternal = true;
		LastRollDashActivationInternal = Time::GameTimeSeconds;
	}

	void StopDash()
	{
		bDashingInternal = false;
	}

	bool IsDashing() const
	{
		return bDashingInternal;
	}

	float GetLastRollDashActivation() const property
	{
		return LastRollDashActivationInternal;
	}
}