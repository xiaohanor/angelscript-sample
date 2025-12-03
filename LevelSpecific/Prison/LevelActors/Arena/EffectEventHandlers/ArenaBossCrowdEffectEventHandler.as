
/**
 * State machine for crowd intensity.
 */

UCLASS(Abstract)
class UArenaBossCrowdEffectEventHandler : UArenaBossEffectEventHandler
{
	// intensity that accelerates towards the requested target
	UPROPERTY(NotVisible)
	FHazeAcceleratedFloat AccIntensity;

	// the request target intensity (that can be interpeted as the immediate intensity)
	UPROPERTY(NotVisible)
	FCrowdIntensityRequest RequestedIntensity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		AccIntensity.SnapTo(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(const float Dt)
	{
		AdvectIntensity(Dt);

		if(Boss == nullptr)
			return;

		Boss.CrowdIntensity = AccIntensity.Value;
	}

	void AdvectIntensity(float Dt)
	{
		float TimeSinceRequest = Time::GetGameTimeSince(RequestedIntensity.ActionTimeStamp);

		float TargetIntensity = 0.0;
		float TargetDuration = 0.0;

		// blend in and stay there for the requested duration
		if(TimeSinceRequest < (RequestedIntensity.Duration_BlendIn + RequestedIntensity.Duration))
		{
			TargetIntensity = RequestedIntensity.Intensity;
			TargetDuration = RequestedIntensity.Duration_BlendIn;
		}
		// blend out
		else
		{
			TargetIntensity = ArenaCrowdSetting::Default;
			TargetDuration = RequestedIntensity.Duration_BlendOut;
		}

		AccIntensity.AccelerateTo(
			TargetIntensity,
			TargetDuration,
			Dt
		);

		// return to default once request has been fully processed
		if(TimeSinceRequest > RequestedIntensity.GetRequestDuration())
			RequestedIntensity = FCrowdIntensityRequest();
	}

	UFUNCTION()
	void RequestIntensityCustom(float Intensity,
								float Duration = 1.0, 
								float Duration_BlendIn = 0.3, 
								float Duration_BlendOut = 0.3
	)
	{
		FCrowdIntensityRequest Request;

		Request.State = GetStateFromIntensity(Intensity);
		Request.Intensity = Intensity;
		Request.Duration = Duration;
		Request.Duration_BlendIn = Duration_BlendIn;
		Request.Duration_BlendOut = Duration_BlendOut;

		Request.ActionTimeStamp = Time::GetGameTimeSeconds();

		// safe up against circular event loops
		if(RequestedIntensity == Request)
		{
			// devError("event loop detected");
			return;
		}

		RequestedIntensity = Request;

	    UArenaBossEffectEventHandler::Trigger_OnIntensityRequested(Owner, Request);
	}

	UFUNCTION()
	void RequestIntensity(	EArenaBossCrowdState State, 
							float Duration = 1.0, 
							float Duration_BlendIn = 0.3, 
							float Duration_BlendOut = 0.3
	)
	{
		FCrowdIntensityRequest Request;

		Request.State = State;
		Request.Intensity = GetIntensityFromState(State);
		Request.Duration = Duration;
		Request.Duration_BlendIn = Duration_BlendIn;
		Request.Duration_BlendOut = Duration_BlendOut;

		Request.ActionTimeStamp = Time::GetGameTimeSeconds();

		// safe up against circular event loops
		if(RequestedIntensity == Request)
		{
			// devError("event loop detected");
			return;
		}

		RequestedIntensity = Request;

	    UArenaBossEffectEventHandler::Trigger_OnIntensityRequested(Owner, Request);
	}

	UFUNCTION(BlueprintPure)
	float GetIntensityFromState(EArenaBossCrowdState State) const
	{
		if(State == EArenaBossCrowdState::Default)
			return ArenaCrowdSetting::Default;

		if(State == EArenaBossCrowdState::Small)
			return ArenaCrowdSetting::Small;

		if(State == EArenaBossCrowdState::Medium)
			return ArenaCrowdSetting::Medium;

		if(State == EArenaBossCrowdState::Large)
			return ArenaCrowdSetting::Large;

		return ArenaCrowdSetting::Default;
	}

	UFUNCTION(BlueprintPure)
	EArenaBossCrowdState GetStateFromIntensity(float Intensity) const
	{
		if(Intensity <= ArenaCrowdSetting::Default)
			return EArenaBossCrowdState::Default;

		if(Intensity <= ArenaCrowdSetting::Small)
			return EArenaBossCrowdState::Small;

		if(Intensity <= ArenaCrowdSetting::Medium)
			return EArenaBossCrowdState::Medium;

		if(Intensity <= ArenaCrowdSetting::Large)
			return EArenaBossCrowdState::Large;

		return EArenaBossCrowdState::Default;
	}

	UFUNCTION(BlueprintPure)
	EArenaBossCrowdState GetCrowdState_Current() const
	{
		return GetStateFromIntensity(AccIntensity.Value);
	}

	UFUNCTION(BlueprintPure)
	EArenaBossCrowdState GetCrowdState_Requested() const
	{
		return GetStateFromIntensity(AccIntensity.Value);
	}

	// the state index that has been requested, which the crowd will eventually reach
	UFUNCTION(BlueprintPure)
	int GetCrowdIntensityStateIndex_Requested() const
	{
		// return Math::IntegerDivisionTrunc(Math::FloorToInt(RequestedIntensity.Intensity*100.0), 100);
		return Math::FloorToInt(RequestedIntensity.Intensity*10.0);
	}

	// the currently accelerated state index 
	UFUNCTION(BlueprintPure)
	int GetCrowdIntensityStateIndex_Current() const
	{
		//return Math::IntegerDivisionTrunc(Math::FloorToInt(AccIntensity.Value*100.0), 100);
		return Math::FloorToInt(AccIntensity.Value*10.0);
	}

	UFUNCTION(BlueprintPure)
	float GetIntensity_Current() const
	{
		return AccIntensity.Value;
	}

	UFUNCTION(BlueprintPure)
	float GetIntensity_Requested() const
	{
		return RequestedIntensity.Intensity;
	}

	UFUNCTION()
	void ClearIntensity()
	{
		RequestIntensityCustom(0.0);
	}

}