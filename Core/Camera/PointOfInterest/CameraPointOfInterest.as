
enum ECameraPointOfInterestTurnType
{
	ShortestPath,	// Camera will try to turn the shortest angular distance in yaw
	Right,			// Camera will turn right (from players perspective) in yaw to reach point of interest
	Left,			// Camera will turn left (from players perspective) in yaw to reach point of interest
};

// How fast should the point of interest approximate its target
enum ECameraPointOfInterestAccelerationType
{
	Slow,			// Will get close to the target slowly (more regular acceleration)
	Medium,			// Will get close to target quickly
	Fast			// Will get close to target very quickly (default behavior)
}

namespace PointOfInterest
{
	const float SlowAccelerationLambertNominator = 4.47228;
	const float MediumAccelerationLambertNominator = 6.63835;
	const float FastAccelerationLambertNominator = 9.23341;

	float GetAcceleratorLambertNominatorForType(ECameraPointOfInterestAccelerationType AccelerationType)
	{
		switch (AccelerationType)
		{
			case ECameraPointOfInterestAccelerationType::Slow:		return SlowAccelerationLambertNominator;
			case ECameraPointOfInterestAccelerationType::Medium:	return MediumAccelerationLambertNominator;
			case ECameraPointOfInterestAccelerationType::Fast:		return FastAccelerationLambertNominator;
		}
	}
}

// Internal settings for the point of interest
struct FApplyPointOfInterestSettings
{
	// For how long the point of interest should be active. -1 it will remain until manually cleared.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings")
	float Duration = -1;

	// How fast we near blend in the desired view rotation.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", AdvancedDisplay)
	ECameraPointOfInterestAccelerationType BlendInAccelerationType = ECameraPointOfInterestAccelerationType::Fast;

	/** 
	 * For how long we should pause point of interest rotation when we have input
	 * Only used if >= 0, else we can't interrupt the poi using input.
	 */ 
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", meta=(ClampMax=2), AdvancedDisplay)
	float InputPauseTime = -1;

	// If true, look in the same direction as the focus target forward instead of looking 'at' focus target
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", AdvancedDisplay)
	bool bMatchFocusDirection = false;

	// Point of interest turn scaling, in case we don't want to apply turn around some axes as fast as others. Values should be 0..1.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", AdvancedDisplay)
	FRotator TurnScaling = FRotator(1, 1, 1);

	// If add, we will remove point of interest if we're looking close to POI and player starts giving input.	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", AdvancedDisplay)
	UCameraPointOfInterestClearOnInputSettings ClearOnInput = nullptr;

	/** How long will it take for us to regain the input after a poi is cleared
	 * Use -1 to apply the blend in time of the poi
	*/ 
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", AdvancedDisplay)
	float RegainInputTime = 2;

	// How camera should turn (in yaw) to reach point of interest.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", AdvancedDisplay)
	ECameraPointOfInterestTurnType TurnDirection = ECameraPointOfInterestTurnType::ShortestPath;

	// If true, the 'Find other player' input is blocked while the poi is active
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", AdvancedDisplay)
	bool bBlockFindAtOtherPlayer = true;

	// Suspends POI based on camera input
	UPROPERTY(NotEditable, BlueprintHidden)
	FPointOfInterestInputSuspensionSettings InputSuspension;
}

struct FPointOfInterestInputSuspensionSettings
{
	UPROPERTY(NotEditable, BlueprintHidden)
	bool bUseInputSuspension = false;

	// How long before POI resumes normally
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Meta = (ClampMin = 0))
	float DelayBeforeResume = 1.0;

	// Should focus target be in sight before we resume
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	bool bResumeWhenFocusTargetIsInView = false;

	// Eman TODOs:
		// Add input threshold for suspension?
		// Add blend back time?
		// Add time focus target needs to remain in view?
}

class UCameraPointOfInterest : UHazePointOfInterestBase
{
	// For how long the point of interest should be active. -1 it will remain until manually cleared.
	FHazePointOfInterestFocusTargetInfo FocusTarget;
	FApplyPointOfInterestSettings Settings;

	private FInstigator ActivationInstigator;
	private FPointOfInterestClearOnInput ClearOnInput;
	private FPointOfInterestPauseOnInput PauseOnInput;
	private FPointOfInterestSuspendOnInput SuspendOnInput;
	private FRotator FocusRotation;
	private float DurationTimeLeft = 0;
	private float BlendInTime = 0;

	private bool bSuspended = false;

	UFUNCTION(BlueprintOverride)
	private bool IsValid() const
	{
		if(!FocusTarget.IsValid())
			return false;

		if(Settings.Duration >= 0 && DurationTimeLeft <= 0)
			return false;

		if (ClearOnInput.ShouldClear())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool IsSuspended() const
	{
		return bSuspended;
	}

	UFUNCTION(BlueprintOverride)
	private void OnActivated(UHazeCameraUserComponent HazeUser, FInstigator Instigator, float Blend)
	{
		auto User = Cast<UCameraUserComponent>(HazeUser);
		auto Player = User.PlayerOwner;
		ActivationInstigator = Instigator;

		BlendInTime = Blend;

		ClearOnInput = FPointOfInterestClearOnInput(Settings.ClearOnInput, Player);
		PauseOnInput = FPointOfInterestPauseOnInput();
		SuspendOnInput = FPointOfInterestSuspendOnInput(Settings.InputSuspension);

		DurationTimeLeft = Settings.Duration + Blend; 	// Also include the blend in, in the duration
		bSuspended = false;

		// Set input sensitivity to zero so it'll return gradually when POI is cleared
	 	auto CameraSettings = UCameraSettings::GetSettings(Player);
		float CurrentSensitivityFactor = CameraSettings.SensitivityFactor.GetValue();
	 	CameraSettings.SensitivityFactor.Apply(0, this, 0, EHazeCameraPriority::Cutscene);
		if (Settings.InputSuspension.bUseInputSuspension)
		{
			// We want camera control when using input suspension
		 	CameraSettings.SensitivityFactor.Apply(CurrentSensitivityFactor, FInstigator(this, n"InputSuspension"), 0, EHazeCameraPriority::Cutscene, 1);
		}

		if(Settings.bBlockFindAtOtherPlayer)
		{
			Player.BlockCapabilities(CapabilityTags::FindOtherPlayer, this);
		}

		FocusRotation = FocusTarget.GetFocusRotation(Player, Settings.bMatchFocusDirection);
	}

	UFUNCTION(BlueprintOverride)
	private void OnDeactivated(UHazeCameraUserComponent HazeUser, FInstigator Instigator)
	{
		auto User = Cast<UCameraUserComponent>(HazeUser);

		// Regain the input amount over time
		float RegainInputTime = Settings.RegainInputTime;
		if(RegainInputTime < 0)
			RegainInputTime = BlendInTime;

		auto CameraSettings = UCameraSettings::GetSettings(User.PlayerOwner);
		CameraSettings.SensitivityFactor.Clear(FInstigator(this, n"InputSuspension"), 0);
	 	CameraSettings.SensitivityFactor.Clear(this, RegainInputTime);

		if(Settings.bBlockFindAtOtherPlayer)
		{
			User.PlayerOwner.UnblockCapabilities(CapabilityTags::FindOtherPlayer, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	private FRotator GetTargetRotation(FHazeCameraTransform CameraTransform) const
	{
		FRotator HerculePOIrot = CameraTransform.WorldToLocalRotation(FocusRotation);
		FRotator CurDesiredRot = CameraTransform.LocalDesiredRotation;
		FRotator TargetDeltaRotation = CurDesiredRot;

		TargetDeltaRotation.Yaw = GetYawByTurnDirection(HerculePOIrot.Yaw, CurDesiredRot.Yaw);
		TargetDeltaRotation.Pitch = CurDesiredRot.Pitch + FRotator::NormalizeAxis(HerculePOIrot.Pitch - CurDesiredRot.Pitch);
		TargetDeltaRotation = GetTurnScaledToRotation(TargetDeltaRotation - CurDesiredRot);

		const FRotator TargetRotation = CameraTransform.LocalToWorldRotation(CurDesiredRot + TargetDeltaRotation);
		return TargetRotation;
	}

	UFUNCTION(BlueprintOverride)
	private void TickActive(UHazeCameraUserComponent HazeUser, float DeltaTime)
	{
		auto User = Cast<UCameraUserComponent>(HazeUser);
		auto Player = User.PlayerOwner;
		const FVector2D AxisInput = Player.GetCameraInput();
		const float CameraDeltaTime = Time::CameraDeltaSeconds;

		if(Settings.Duration >= 0)
			DurationTimeLeft -= CameraDeltaTime;

		FocusRotation = FocusTarget.GetFocusRotation(Player, Settings.bMatchFocusDirection);

		ClearOnInput.Update(FocusRotation, AxisInput, User);
		PauseOnInput.Update(CameraDeltaTime, Settings.InputPauseTime, !AxisInput.IsNearlyZero());

		auto CameraUserComponent = Cast<UCameraUserComponent>(HazeUser);
		if (CameraUserComponent != nullptr)
			SuspendOnInput.Update(Player, FocusTarget, DeltaTime, CameraUserComponent.DesiredRotationChangedLastFrame(), bSuspended);
	}

	UFUNCTION(BlueprintOverride)
	void GetDebugDescription(bool bIsCurrentValue, FString& Desc)
	{
		if(bIsCurrentValue)
		{
			Desc = "\n" + FocusTarget.ToString();
			if (Settings.bMatchFocusDirection)
				Desc += "\n(Matching rotation)";
		}
	}

	private float GetYawByTurnDirection(float POIYaw, float CurrentYaw) const
	{
		float Delta = (CurrentYaw - POIYaw); // Non-normalized delta
		float ShortestPathYaw = CurrentYaw - FRotator::NormalizeAxis(Delta); 
		if (Settings.TurnDirection == ECameraPointOfInterestTurnType::ShortestPath)
			return ShortestPathYaw;

		// Should we force turn to the right or left?
		if ((Settings.TurnDirection == ECameraPointOfInterestTurnType::Right) && (Delta < 0.0))
			return POIYaw - 360.0;
		if ((Settings.TurnDirection == ECameraPointOfInterestTurnType::Left) && (Delta > 0.0))
			return POIYaw + 360.0;

		return POIYaw;
	}

	private FRotator GetTurnScaledToRotation(FRotator Rotator) const
	{
		FRotator Result = Rotator.GetNormalized();
		Result.Yaw *= Settings.TurnScaling.Yaw;
		Result.Pitch *= Settings.TurnScaling.Pitch;
		Result.Roll *= Settings.TurnScaling.Roll;
		return Result * PauseOnInput.Weight;
	}

	UFUNCTION(BlueprintOverride)
	float GetAcceleratorLambertNominator() const
	{
		return PointOfInterest::GetAcceleratorLambertNominatorForType(Settings.BlendInAccelerationType);
	}
}

// Force camera to look at given point of interest if able to.
mixin UCameraPointOfInterest CreatePointOfInterest(AHazePlayerCharacter Player)
{
	auto Out = NewObject(Player, UCameraPointOfInterest);
	return Out;
}

