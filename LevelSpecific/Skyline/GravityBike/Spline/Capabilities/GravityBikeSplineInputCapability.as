struct FGravityBikeSplineStickyThrottle
{
	private FHazeAcceleratedFloat AccStickyThrottle;
	private float ThrottleTime = 0;
	private float StickyThrottle;
	private float CurrentImmediateThrottle;
	private float PreviousImmediateThrottle;

	void ApplyThrottleInput(const AGravityBikeSpline GravityBike, float Input, float DeltaTime)
	{
		PreviousImmediateThrottle = CurrentImmediateThrottle;
		CurrentImmediateThrottle = Input;

		if(Input > 0.5)
		{
			ThrottleTime = Time::GameTimeSeconds;
			StickyThrottle = Input;

			AccStickyThrottle.AccelerateTo(Input, GravityBike.Settings.ThrottleIncreaseDuration, DeltaTime);
		}
		else if(Time::GetGameTimeSince(ThrottleTime) < GravityBike.Settings.ThrottleStickTime)
		{
			AccStickyThrottle.AccelerateTo(StickyThrottle, GravityBike.Settings.ThrottleIncreaseDuration, DeltaTime);
		}
		else
		{
			AccStickyThrottle.AccelerateTo(0, GravityBike.Settings.ThrottleDecreaseDuration, DeltaTime);
		}
	}

	float GetStickyThrottle() const
	{
		return AccStickyThrottle.Value;
	}

	float GetImmediateThrottle() const
	{
		return CurrentImmediateThrottle;
	}

	bool IsThrottling() const
	{
		return CurrentImmediateThrottle > 0.5;
	}

	bool WasThrottling() const
	{
		return PreviousImmediateThrottle > 0.5;	
	}

	bool StartedThrottling() const
	{
		return !WasThrottling() && IsThrottling();
	}

	bool StoppedThrottling() const
	{
		return WasThrottling() && !IsThrottling();
	}

	void Reset()
	{
		AccStickyThrottle.SnapTo(0);
		ThrottleTime = 0;
		StickyThrottle = 0;
		CurrentImmediateThrottle = 0;
		PreviousImmediateThrottle = 0;
	}
}

class UGravityBikeSplineInputCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);

    default TickGroup = EHazeTickGroup::Input;

    AGravityBikeSpline GravityBike;
    AHazePlayerCharacter Driver;

	bool bHasGivenInput = false;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        GravityBike = Cast<AGravityBikeSpline>(Owner);
		Driver = GravityBike.GetDriver();
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
		if(!HasControl())
			return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if(!HasControl())
			return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(GravityBike.Input.Throttle.WasThrottling())
			CrumbStopThrottle();
		
		GravityBike.Input.Reset();
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if(!bHasGivenInput)
			bHasGivenInput = IsInputting() || ActiveDuration > GravityBike.Settings.ForceInputDuration;

		float ThrottleInput = 0;

		if(bHasGivenInput)
			ThrottleInput = GetThrottleInput();
		else
			ThrottleInput = 1.0;	// If we have not given any input, force hold throttle

		if(GravityBike.IsBoosting())
		{
			ThrottleInput = 1.0;
		}
#if !RELEASE
		else if(DevToggleGravityBikeSpline::AutoThrottle.IsEnabled())
		{
			ThrottleInput = 1.0;
		}
#endif

		GravityBike.Input.ControlSetSteering(GetAttributeFloat(AttributeNames::MoveRight));

		GravityBike.Input.Throttle.ApplyThrottleInput(GravityBike, ThrottleInput, DeltaTime);

		if(GravityBike.Input.Throttle.StartedThrottling())
			CrumbStartThrottle();
		else if(GravityBike.Input.Throttle.StoppedThrottling())
			CrumbStopThrottle();
    }

	float GetThrottleInput() const
	{
		if(!GravityBike.ForceThrottle.IsEmpty())
			return 1.0;

		return Math::Max(GetAttributeFloat(AttributeNames::Accelerate), 0);
	}

    void DebugInput() const
    {
        Print("Immediate Throttle: " + GravityBike.Input.GetImmediateThrottle(), 0.0);
        Print("Sticky Throttle: " + GravityBike.Input.GetStickyThrottle(), 0.0);
        Print("Steering: " + GravityBike.Input.GetSteering(), 0.0);

        const FVector Start = GravityBike.Sphere.WorldLocation;
        const float ArrowLength = 300;
        const float ArrowSize = 15;
        Debug::DrawDebugDirectionArrow(Start, GravityBike.ActorForwardVector, GravityBike.Input.GetImmediateThrottle() * ArrowLength, ArrowSize, FLinearColor::Red);
        Debug::DrawDebugDirectionArrow(Start, GravityBike.ActorRightVector, GravityBike.Input.GetSteering() * ArrowLength, ArrowSize, FLinearColor::Green);
        Debug::DrawDebugDirectionArrow(Start, GravityBike.SteeringComp.GetSteeringWorldDir(), ArrowLength, ArrowSize, FLinearColor::LucBlue);
    }

	bool IsInputting() const
	{
		if(IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStartThrottle()
	{
		UGravityBikeSplineEventHandler::Trigger_OnThrottleStart(GravityBike);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStopThrottle()
	{
		UGravityBikeSplineEventHandler::Trigger_OnThrottleEnd(GravityBike);
	}
};