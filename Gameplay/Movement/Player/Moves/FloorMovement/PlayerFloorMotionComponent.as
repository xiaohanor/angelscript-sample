
class UPlayerFloorMotionComponent : UActorComponent
{
	UPROPERTY()
	UPlayerFloorMotionSettings Settings;
	
	FPlayerFloorMotionData Data;

	UPROPERTY(BlueprintReadOnly)
	FPlayerFloorMotionAnimData AnimData;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> HighSpeedLandingShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect HighSpeedLandingFF;

	float LastLandedTime;
	ETurnaroundDebugModes TurnaroundModes;

	//Blockers for "AnimationOnly" moving object balance behavior
	private TArray<FInstigator> MovingBalanceBlockers;
	//Blockers for "AnimationOnly" relax / idle behavior
	private TArray<FInstigator> RelaxIdleBlockers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerFloorMotionSettings::GetSettings(Cast<AHazeActor>(Owner));

		FHazeDevInputInfo DevInput;
		DevInput.Name = n"Turnaround Mode";
		DevInput.Category = n"Movement";
		DevInput.AddAction(ActionNames::MovementDash);
		DevInput.OnTriggered.BindUFunction(this, n"OnTurnaroundModeChanged");
		DevInput.OnStatus.BindUFunction(this, n"OnTurnaroundModeStatus");
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		Player.RegisterDevInput(DevInput);
	}

	UFUNCTION()
	private void OnTurnaroundModeStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		switch (TurnaroundModes)
		{
			case(ETurnaroundDebugModes::Default):
				OutDescription = "[Default]";
				OutColor = FLinearColor::Green;
				break;

			case(ETurnaroundDebugModes::NoStopDuration):
				OutDescription = "[NoStopDuration]";
				OutColor = FLinearColor::Yellow;
				break;

			case(ETurnaroundDebugModes::Disabled):
				OutDescription = "[Disabled]";
				OutColor = FLinearColor::Red;
				break;

			default:
				break;
		}
	}

	UFUNCTION()
	private void OnTurnaroundModeChanged()
	{
		switch (TurnaroundModes)
		{
			case(ETurnaroundDebugModes::Default):
				TurnaroundModes = ETurnaroundDebugModes::NoStopDuration;
				break;

			case(ETurnaroundDebugModes::NoStopDuration):
				TurnaroundModes = ETurnaroundDebugModes::Disabled;
				break;

			case(ETurnaroundDebugModes::Disabled):
				TurnaroundModes = ETurnaroundDebugModes::Default;
				break;

			default:
				break;
		}
	}

	float GetMovementTargetSpeed(float SpeedAlpha) const
	{
		return Math::Lerp(Settings.MinimumSpeed, Settings.MaximumSpeed, SpeedAlpha);
	}	

	//Frame number is not the way to go here, here we want gametime instead since the capability logic is driven by time
	void ActivatedSprintTurnaround()
	{
		Data.SprintTurnaroundActivatedAtTime = Time::GetGameTimeSeconds();
	}

	float GetMinSpeed() const
	{
		return Settings.MaximumSpeed;
	}

	float GetMaxSpeed() const
	{
		return Settings.MaximumSpeed;
	}

	bool IsMovingBalanceBlocked() const
	{
		return MovingBalanceBlockers.Num() > 0;
	}

	void AddMovingBalanceBlocker(FInstigator Instigator)
	{
		MovingBalanceBlockers.Add(Instigator);
	}

	void ClearMovingBalanceBlocker(FInstigator Instigator)
	{
		MovingBalanceBlockers.RemoveSingleSwap(Instigator);
	}

	bool IsRelaxIdleBlocked() const
	{
		return RelaxIdleBlockers.Num() > 0;
	}

	void AddRelaxIdleBlocker(FInstigator Instigator)
	{
		RelaxIdleBlockers.Add(Instigator);
	}

	void ClearRelaxIdleBlocker(FInstigator Instigator)
	{
		RelaxIdleBlockers.RemoveSingleSwap(Instigator);
	}
}

struct FPlayerFloorMotionData
{
	float SprintTurnaroundActivatedAtTime = 0;	

	bool bForceHighSpeedLanding = false;
	float ForceHighSpeedExitSpeed;
	FVector ForceHighSpeedLandingVelocity;

	void ResetForceHighSpeedlandingData()
	{
		bForceHighSpeedLanding = false;
		ForceHighSpeedExitSpeed = - 1.0;
		ForceHighSpeedLandingVelocity = FVector::ZeroVector;
	}
}

struct FPlayerFloorMotionAnimData
{
	//The vertical speed when transitioning from airborne.
	UPROPERTY()
	float VerticalLandingSpeed;

	UPROPERTY()
	bool bTurnaroundTriggered;

	UPROPERTY()
	bool bSprintTurnaroundTriggered;

	UPROPERTY()
	bool bTriggeredHighSpeedLanding;
}