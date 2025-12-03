struct FGravityBikeSplineAutoSteerSettings
{
	UPROPERTY()
	FRotator AutoSteerTargetRotation;

	/**
	 * How strong the auto steer should be. 1 means that it could fully override player input.
	 */
	UPROPERTY(Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float AutoSteerInfluence = 0.7;

	/**
	 * How much angle difference is needed for full auto steer input.
	 */
	UPROPERTY(Meta = (ClampMin = "0.0", ClampMax = "45.0"))
	float AutoSteerThresholdDegrees = 20;
};

UCLASS(NotBlueprintable)
class UGravityBikeSplineAutoSteerComponent : UActorComponent
{
	access Internal = private, UGravityBikeSplineAutoSteerCapability;

	private AGravityBikeSpline GravityBike;

	access:Internal
	bool bIsAutoSteering = false;
	TInstigated<FGravityBikeSplineAutoSteerSettings> Settings;

	TArray<AGravityBikeSplineAutoSteerVolume> CurrentAutoSteerVolumes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("bIsAutoSteering", bIsAutoSteering)
			.Value("CurrentAutoSteerVolumes Count", CurrentAutoSteerVolumes.Num())
			.Struct("Settings;", Settings.Get())
		;
#endif
	}

	void TryApplyAutoSteer(float& SteeringInput) const
	{
		if(!bIsAutoSteering)
			return;

		SteeringInput += GetAutoSteeringInput();
		SteeringInput = Math::Clamp(SteeringInput, -1, 1);
	}

	float GetAutoSteeringInput() const
	{
		const FVector WorldUp = GravityBike.GetGlobalWorldUp();
		const FQuat CurrentRotation = FQuat::MakeFromZX(WorldUp, GravityBike.ActorForwardVector);
		const FQuat TargetRotation = FQuat::MakeFromZX(WorldUp, Settings.Get().AutoSteerTargetRotation.ForwardVector);

		float Angle = CurrentRotation.AngularDistance(TargetRotation);
		const bool bTurnLeft = CurrentRotation.ForwardVector.DotProduct(TargetRotation.RightVector) > 0;

		if(bTurnLeft)
			Angle = -Angle;

		const float Influence = Settings.Get().AutoSteerInfluence;
		const float Threshold = Math::DegreesToRadians(Settings.Get().AutoSteerThresholdDegrees);
		const float Steering =  Math::GetMappedRangeValueClamped(
			FVector2D(-Threshold, Threshold),
			FVector2D(-Influence, Influence),
			Angle
		);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		const FVector AboveBike = GravityBike.ActorCenterLocation + FVector(0, 0, 200);
		TemporalLog.DirectionalArrow("Current", AboveBike, CurrentRotation.ForwardVector * 500, 10, 20, FLinearColor::Red);
		TemporalLog.DirectionalArrow("Target", AboveBike, TargetRotation.ForwardVector * 500, 10, 20, FLinearColor::Green);

		TemporalLog.Value("Angle", Angle);
		TemporalLog.Value("Steering", Steering);
#endif

		return Steering;
	}
};