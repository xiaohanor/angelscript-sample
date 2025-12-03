UCLASS(Abstract)
class UGravityBikeFreeBoostComponent : UActorComponent
{
	access Internal = private, UGravityBikeFreeBoostCapability;
	UPROPERTY(Category = "Boost")
    UCurveFloat BoostCurve;

	UPROPERTY(Category = "Boost")
    UCurveFloat BoostFOVCurve;

	private AGravityBikeFree GravityBike;

	private TInstigated<bool> ForceBoost;
	default ForceBoost.DefaultValue = false;

	access:Internal
	bool bIsBoosting = false;

	access:Internal
	float StartBoostTime = 0;

	access:Internal
	uint ApplyBoostFrame = 0;

	private float BoostUntilTime;

	UGravityBikeFreeBoostSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		Settings = UGravityBikeFreeBoostSettings::GetSettings(GravityBike);
	}

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("Is Boosting", IsBoosting());
		TemporalLog.Value("Force Boost", ForceBoost.Get());
		TemporalLog.Value("Boost Until Time", BoostUntilTime);

		if(IsBoosting())
		{
			TemporalLog.Value("Boost Acceleration", CalculateBoostAcceleration());
		}
	}
	#endif

	void SetBoostUntilTime(float InBoostUntilTime)
	{
		if(InBoostUntilTime < BoostUntilTime)
			return;

		StartBoostTime = Time::GameTimeSeconds;
		BoostUntilTime = InBoostUntilTime;
		ApplyBoostFrame = Time::FrameNumber;
	}

	float GetBoostUntilTime() const
	{
		return BoostUntilTime;
	}

	float GetBoostActiveDuration() const
	{
		check(IsBoosting());
		return Time::GetGameTimeSince(StartBoostTime);
	}

	bool ShouldBoost() const
	{
		if(ForceBoost.Get())
			return true;

		return BoostUntilTime >= Time::GameTimeSeconds;
	}
	
	bool IsBoosting() const
	{
		return bIsBoosting;
	}

	float GetBoostFactor() const
	{
		check(IsBoosting());
		float MaxBoostTime = Settings.MaxBoostTime;
		float Alpha = Math::Saturate(GetBoostActiveDuration() / MaxBoostTime);
		return BoostCurve.GetFloatValue(Alpha);
	}

	float CalculateBoostAcceleration() const
	{
		return GetBoostFactor() * Settings.BoostAcceleration * Settings.BoostScale;
	}

	void ApplyForceBoost(bool bForceBoost, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		ForceBoost.Apply(bForceBoost, Instigator, Priority);
		ApplyBoostFrame = Time::FrameNumber;
	}

	void ClearForceBoost(FInstigator Instigator)
	{
		ForceBoost.Clear(Instigator);
	}

	bool AppliedBoostThisFrame() const
	{
		return ApplyBoostFrame == Time::FrameNumber;
	}
};

mixin bool IsBoosting(AGravityBikeFree GravityBike)
{
	auto BoostComp = UGravityBikeFreeBoostComponent::Get(GravityBike);
	if(BoostComp == nullptr)
		return false;

	return BoostComp.IsBoosting();
}

mixin void AddBoost(AGravityBikeFree GravityBike, UGravityBikeFreeMovementData& Movement, FVector Dir = FVector::ZeroVector)
{
	auto BoostComp = UGravityBikeFreeBoostComponent::Get(GravityBike);
	if(BoostComp == nullptr)
		return;

	if(BoostComp.Settings.ApplyMode != EGravityBikeFreeBoostApplyMode::Acceleration)
		return;

	if(!BoostComp.IsBoosting())
		return;

	FVector BoostDir = Dir;
	if(BoostDir.IsNearlyZero())
		BoostDir = GravityBike.ActorForwardVector;

	BoostDir.Normalize();

	const float BoostAcceleration = BoostComp.CalculateBoostAcceleration();
	Movement.AddHorizontalAcceleration(BoostDir * BoostAcceleration);
}