UCLASS(Abstract)
class UGravityBikeSplineBoostComponent : UActorComponent
{
	access Internal = private, UGravityBikeSplineBoostCapability;

	UPROPERTY(Category = "Boost")
    UCurveFloat BoostCurve;

	UPROPERTY(Category = "Boost")
    UCurveFloat BoostFOVCurve;

	private float BoostUntilTime_Internal;
	TSet<FInstigator> ForceBoost;

	UGravityBikeSplineBoostSettings Settings;
	float TimeToBoost;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto GravityBike = Cast<AGravityBikeSpline>(Owner);
		Settings = UGravityBikeSplineBoostSettings::GetSettings(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this)
			.Value("ForceBoost", !ForceBoost.IsEmpty())
			.Value("BoostUntilTime", BoostUntilTime_Internal)
		;
	}

	void ApplyBoost(float InBoostDuration)
	{
		check(InBoostDuration <= Settings.MaxBoostTime);

		if(Time::GameTimeSeconds + InBoostDuration < BoostUntilTime_Internal)
			return;

		BoostUntilTime_Internal = Time::GameTimeSeconds + InBoostDuration;
	}

	float GetBoostUntilTime() const property
	{
		return BoostUntilTime_Internal;
	}

	UFUNCTION(BlueprintPure)
	bool IsBoosting() const
	{
		return BoostUntilTime_Internal >= Time::GameTimeSeconds || !ForceBoost.IsEmpty();
	}

	float GetBoostFactor() const
	{
		if(!ForceBoost.IsEmpty())
			return 1;

		check(TimeToBoost <= Settings.MaxBoostTime);
		return TimeToBoost / Settings.MaxBoostTime;
	}
};

mixin bool IsBoosting(AGravityBikeSpline GravityBike)
{
	auto BoostComp = UGravityBikeSplineBoostComponent::Get(GravityBike);
	if(BoostComp == nullptr)
		return false;

	return BoostComp.IsBoosting();
}

mixin void ApplyBoost(AGravityBikeSpline GravityBike, float InBoostDuration)
{
	auto BoostComp = UGravityBikeSplineBoostComponent::Get(GravityBike);
	if(BoostComp == nullptr)
		return;

	BoostComp.ApplyBoost(InBoostDuration);
}

mixin void ApplyFullBoost(AGravityBikeSpline GravityBike)
{
	auto BoostComp = UGravityBikeSplineBoostComponent::Get(GravityBike);
	if(BoostComp == nullptr)
		return;

	BoostComp.ApplyBoost(BoostComp.Settings.MaxBoostTime);
}