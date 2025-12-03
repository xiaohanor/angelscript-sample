
/**
 * Default asset when wanting to clear the input on poi's
 */
asset CameraPOIDefaultClearOnInput of UCameraPointOfInterestClearOnInputSettings
{
	
}

/**
 * 
 */
class UCameraPointOfInterestClearOnInputSettings : UDataAsset
{
    // What fraction of full input we have to drop below before we count as giving no input
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraPointOfInterestBehavior")
    float NoInputThreshold = 0.01;

    // What fraction of full input be have to give before we can consider clearing point of interest
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraPointOfInterestBehavior")
    float InputClearThreshold = 0.1;

    // We need to be within this angle of POI before clearing
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraPointOfInterestBehavior")
    float InputClearAngleThreshold = 5.0;

    // After matching POI rotation we will not be able to clear POI until after this delay
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraPointOfInterestBehavior")
    float InputClearWithinAngleDelay = 0.1;

    // We need to give input for this duration for POI to clear
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraPointOfInterestBehavior")
    float InputClearDuration = 0.05;

	// Whether we want to start counting while POI is blending in
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraPointOfInterestBehavior")
	bool bClearDurationOverridesBlendIn = false;
}

/**
 * 
 */
struct FPointOfInterestClearOnInput
{
	private UCameraPointOfInterestClearOnInputSettings Settings;
	private UHazeCrumbSyncedFloatComponent CrumbedInputDuration;

	private float MatchedAngleDelayTime = 0.0;
	private bool bHasReleasedInput = false;

	FPointOfInterestClearOnInput(UCameraPointOfInterestClearOnInputSettings InSettings, AHazePlayerCharacter Player)
	{
		Settings = InSettings;
		CrumbedInputDuration = UHazeCrumbSyncedFloatComponent::GetOrCreate(Player, n"PointOfInterestClearOnInputDuration");
	}

	bool ShouldClear() const
	{
		if(Settings == nullptr)
			return false;

		// Note: Input clear duration of zero should still requires one frame of input
		if (CrumbedInputDuration.Value < Settings.InputClearDuration + SMALL_NUMBER) 
			return false;
		
		if (MatchedAngleDelayTime == 0.0)
			return false;

		if (Time::GetRealTimeSeconds() < MatchedAngleDelayTime)
			return false;
		
		return true;
	}

	void Update(FRotator POIRot, FVector2D Input, UCameraUserComponent User)
	{
		if(Settings == nullptr)
			return;

		const float InputSqr = Input.SizeSquared();
		if ((InputSqr < Math::Square(Settings.NoInputThreshold)) || (Settings.NoInputThreshold <= 0.0))
			bHasReleasedInput = true;

		if (MatchedAngleDelayTime == 0.0)
		{		
			// We haven't yet matched angle enough to consider clearing input,
			// check if that's changed
			FRotator ViewRot = User.WorldToLocalRotation(User.GetActiveCameraRotation());
			if ((POIRot - ViewRot).IsNearlyZero(Settings.InputClearAngleThreshold))
			{
				// Now we are close enough, set delay until we can clear POI
				MatchedAngleDelayTime = Time::GetRealTimeSeconds() + Settings.InputClearWithinAngleDelay;
			}
		}

		if (InputSqr > Math::Square(Settings.InputClearThreshold))
		{

			// Accumulate input duration when we've stopped giving input and started again
			CrumbedInputDuration.Value += Time::CameraDeltaSeconds;
		}	
		else
		{
			// Too little input, reset count
			CrumbedInputDuration.Value = 0.0;
		}
	}
}


struct FPointOfInterestPauseOnInput
{
	private float HasReceivedInputTimer = 0;
	private float InternalWeight = 1;

	void Update(float DeltaTime, float InputPauseTime, bool bHasInput)
	{
		if(InputPauseTime >= 0)
		{	
			if(bHasInput)
			{
				HasReceivedInputTimer = InputPauseTime;
				InternalWeight = 0;
			}
			else if(HasReceivedInputTimer > 0)
			{
				HasReceivedInputTimer -= DeltaTime;
			}
			else
			{
				InternalWeight = Math::FInterpConstantTo(InternalWeight, 1, DeltaTime, 1);
			}
		}
		else
		{
			InternalWeight = 1;
			HasReceivedInputTimer = 0;
		}
	}

	float GetWeight() const property
	{
		return InternalWeight;
	}
}


struct FPointOfInterestSuspendOnInput
{
	private FPointOfInterestInputSuspensionSettings Settings;
	private float TimeSinceResume;

	FPointOfInterestSuspendOnInput(FPointOfInterestInputSuspensionSettings InputSuspensionSettings)
	{
		Settings = InputSuspensionSettings;
		TimeSinceResume = 0;
	}

	void Update(AHazePlayerCharacter Player, const FHazePointOfInterestFocusTargetInfo& FocusTarget, float DeltaTime, bool bHasInput, bool& bOutSuspended)
	{
		if (!Settings.bUseInputSuspension)
			return;

		if (bOutSuspended)
		{
			if (bHasInput)
			{
				TimeSinceResume = 0;
			}
			else
			{
				if (CanResume(Player, FocusTarget))
				{
					if (TimeSinceResume >= Settings.DelayBeforeResume)
						bOutSuspended = false;

					TimeSinceResume += DeltaTime;
				}
			}
		}
		else
		{
			if (bHasInput)
			{
				bOutSuspended = true;
			}
		}
	}

	private bool CanResume(AHazePlayerCharacter Player, const FHazePointOfInterestFocusTargetInfo& FocusTarget) const
	{
		if (Settings.bResumeWhenFocusTargetIsInView)
		{
			// Check if focus target is in view
			FVector FocusLocation = FocusTarget.GetFocusLocation(Player);
			if (!SceneView::IsInView(Player, FocusLocation))
				return false;
		}

		return true;
	}
}