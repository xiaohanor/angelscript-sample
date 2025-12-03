struct FJetskiInput
{
	access Input = private, UJetskiInputCapability, FJetskiInput;

	access:Input float Acceleration;
	access:Input float Steering;
	access:Input float SteeringBias;
	access:Input float Dive;

	const float DEADZONE = 0.1;

	float GetAcceleration() const
	{
		return Acceleration;
	}

	bool IsThrottling() const
	{
		return Acceleration > DEADZONE;
	}

	float GetSteering() const
	{
		return Steering;
	}

	bool IsSteering() const
	{
		return Math::Abs(Steering) > DEADZONE;
	}

	float GetSteeringBias() const
	{
		return Math::Abs(SteeringBias);
	}

	bool IsActioningDive() const
	{
		return Dive > DEADZONE;
	}

	void Reset()
	{
		Acceleration = 0.0;
		Steering = 0.0;
		SteeringBias = 0.0;
		Dive = 0.0;
	}
};

namespace FJetskiInput
{
	FJetskiInput Lerp(FJetskiInput A, FJetskiInput B, float Alpha)
	{
		check(Alpha >= 0 && Alpha <= 1.0);
		FJetskiInput Out;
		Out.Acceleration = Math::Lerp(A.Acceleration, B.Acceleration, Alpha);
		Out.Steering = Math::Lerp(A.Steering, B.Steering, Alpha);
		Out.SteeringBias = Math::Lerp(A.SteeringBias, B.SteeringBias, Alpha);
		Out.Dive = Math::Lerp(A.Dive, B.Dive, Alpha);
		return Out;
	}
}

class UJetskiInputCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default TickGroup = EHazeTickGroup::Input;

	AJetski Jetski;
	bool bHasBroadcastStartThrottle = false;
	bool bHoldThrottle = true;

	FHazeAcceleratedFloat ForceFeedbackMultiplier;
	default ForceFeedbackMultiplier.Value = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(Jetski.Driver == nullptr)
			return false;

		if(Jetski.Driver.IsPlayerDead() || Jetski.Driver.IsPlayerRespawning())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HasControl())
			return true;

		if(Jetski.Driver == nullptr)
			return true;
		
		if(Jetski.Driver.IsPlayerDead() || Jetski.Driver.IsPlayerRespawning())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHoldThrottle = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Jetski.Input.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
#if !RELEASE
		TemporalLog.Value("Acceleration", Jetski.Input.Acceleration);
		TemporalLog.Value("Steering", Jetski.Input.Steering);
		TemporalLog.Value("Dive", Jetski.Input.Dive);
		TemporalLog.Value("SteeringBias", Jetski.Input.SteeringBias);
		TemporalLog.Value("bHoldThrottle", bHoldThrottle);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		UpdateIsThrottling();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		check(HasControl());

		Jetski.Input.Acceleration = GetAttributeFloat(AttributeNames::Accelerate);
		Jetski.TryGetForceThrottle(Jetski.Input.Acceleration);

		if(Jetski.Input.IsThrottling() || ActiveDuration > Jetski.Settings.InitialHoldThrottleDuration)
			bHoldThrottle = false;

		if(bHoldThrottle)
			Jetski.Input.Acceleration = Jetski.Settings.InitialHoldThrottle;

		Jetski.Input.Steering = GetAttributeFloat(AttributeNames::MoveRight);

		if(Jetski.IsCapabilityTagBlocked(Jetski::Tags::JetskiDive))
			Jetski.Input.Dive = 0;
		else
			Jetski.Input.Dive = GetAttributeFloat(AttributeNames::SecondaryLevelAbilityAxis);

		if(Math::IsNearlyZero(Jetski.Input.Steering) || Math::Sign(Jetski.Input.Steering) != Math::Sign(Jetski.Input.SteeringBias))
		{
			// Reset steering bias on no input or other input direction
			Jetski.Input.SteeringBias = 0;
		}

		Jetski.Input.SteeringBias += (Jetski.Input.Steering * DeltaTime) / Jetski.Settings.SteeringBiasTimeToReachFullTurnSeconds;
		Jetski.Input.SteeringBias = Math::Clamp(Jetski.Input.SteeringBias, -1, 1);

		if(Jetski.Input.IsThrottling())
			ForceFeedbackMultiplier.AccelerateTo(1.0, 1.5, DeltaTime);
		else
			ForceFeedbackMultiplier.AccelerateTo(0.0, 1.5, DeltaTime);

		FHazeFrameForceFeedback FF;
		FF.LeftMotor = 0.0;
		FF.RightMotor = 0.25 * ForceFeedbackMultiplier.Value;
		Jetski.Driver.SetFrameForceFeedback(FF);
	}

	void UpdateIsThrottling()
	{
		bool bIsThrottling = Jetski.Input.IsThrottling();

		if(Jetski.IsUnderwater() && Jetski.Input.IsActioningDive())
			bIsThrottling = true;

		if(bHasBroadcastStartThrottle == bIsThrottling)
			return;

		if(bIsThrottling)
			UJetskiEventHandler::Trigger_OnStartThrottle(Jetski);
		else
			UJetskiEventHandler::Trigger_OnStopThrottle(Jetski);

		bHasBroadcastStartThrottle = bIsThrottling;
	}
};