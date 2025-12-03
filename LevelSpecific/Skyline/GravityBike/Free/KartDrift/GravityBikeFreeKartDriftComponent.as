UCLASS(Abstract)
class UGravityBikeFreeKartDriftComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset DriftCameraSettings;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeKartDriftSettings Settings;

	bool bIsDriftJumping = false;

	private bool bIsDrifting = false;
	bool bDriftLeft = false;
	private float StartDriftTime = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		Settings = UGravityBikeFreeKartDriftSettings::GetSettings(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("bIsDriftJumping", bIsDriftJumping);
		TemporalLog.Value("bIsDrifting", bIsDrifting);
		TemporalLog.Value("bDriftLeft", bDriftLeft);
		TemporalLog.Value("StartDriftTime", StartDriftTime);
#endif
	}

	void StartDrifting(bool bInDriftLeft)
	{
		bIsDrifting = true;
		bDriftLeft = bInDriftLeft;
		StartDriftTime = Time::GameTimeSeconds;
	}

	void StopDrifting()
	{
		bIsDrifting = false;
	}

	bool IsDriftJumping() const
	{
		return bIsDriftJumping;
	}

	bool IsDrifting() const
	{
		return bIsDrifting;
	}

	float GetDriftActiveDuration() const
	{
		check(IsDrifting());
		return Time::GetGameTimeSince(StartDriftTime);
	}

	/**
	 * 0 -> 0.5: Steering against the drift
	 * 0.5: Idle
	 * 0.5 -> 1.0: Steering into the drift
	 * @param bAbsolute If false, drifting left will return a negative value.
	 */
	float GetSteerIntoDriftFactor(bool bAbsolute = true) const
	{
		float SteeringInput = GravityBike.AccSteering.Value;
		const bool bIsTurningIntoDrift = SteeringInput < 0 == bDriftLeft;
		SteeringInput = Math::Abs(SteeringInput);

		float SteerIntoDriftFactor = 0;
		if(bIsTurningIntoDrift)
			SteerIntoDriftFactor = Math::Lerp(0.5, 1, SteeringInput);
		else
			SteerIntoDriftFactor = Math::Lerp(0.5, 0, SteeringInput);

		if(!bAbsolute && bDriftLeft)
			SteerIntoDriftFactor *= -1;

		return SteerIntoDriftFactor;
	}

	float GetDriftSteeringAngle(float Min, float Default, float Max) const
	{
		float SteerIntoDriftFactor = GetSteerIntoDriftFactor();

		float TurnAmount = 0;

		if(SteerIntoDriftFactor < 0.5)
		{
			// Steering against the drift
			TurnAmount = Math::Lerp(Min, Default, SteerIntoDriftFactor * 2);
		}
		else
		{
			// Steering into the drift
			TurnAmount = Math::Lerp(Default, Max, (SteerIntoDriftFactor - 0.5) * 2);
		}

		if(bDriftLeft)
			TurnAmount *= -1;

		return TurnAmount;
	}
};

mixin bool IsKartDrifting(AGravityBikeFree GravityBike)
{
	auto KartDriftComp = UGravityBikeFreeKartDriftComponent::Get(GravityBike);
	if(KartDriftComp == nullptr)
		return false;

	return KartDriftComp.IsDrifting();
};

mixin bool IsKartJumping(AGravityBikeFree GravityBike)
{
	auto KartDriftComp = UGravityBikeFreeKartDriftComponent::Get(GravityBike);
	if(KartDriftComp == nullptr)
		return false;

	return KartDriftComp.IsDriftJumping();
}