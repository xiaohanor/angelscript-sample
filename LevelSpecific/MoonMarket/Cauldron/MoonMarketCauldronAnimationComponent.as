event void FCauldronOnAnimationDone();

class UMoonMarketCauldronAnimationComponent : USceneComponent
{
	FVector StartLocation;

	UPROPERTY()
	FCauldronOnAnimationDone AnimationDone;

	UPROPERTY()
	FRuntimeFloatCurve XScaleCurve;

	UPROPERTY()
	FRuntimeFloatCurve YScaleCurve;

	UPROPERTY()
	FRuntimeFloatCurve ZScaleCurve;


	UPROPERTY()
	FRuntimeFloatCurve ZOffsetCurve;

	UPROPERTY()
	FRuntimeFloatCurve YawCurve;

	UPROPERTY()
	const float HeightOffsetMax = 120;

	float StartTime;
	bool bReversed = false;

	UPROPERTY(EditAnywhere)
	const float Duration = 2;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = RelativeLocation;
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintCallable)
	void StartAnimation()
	{
		Timer::SetTimer(this, n"Finish", Duration);
		StartTime = Time::GameTimeSeconds;
		bReversed = false;
		SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintCallable)
	void StartAnimationReverse()
	{
		Timer::SetTimer(this, n"Finish", Duration);
		StartTime = Time::GameTimeSeconds;
		bReversed = true;
		SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintCallable)
	void Finish()
	{
		// SetRelativeLocation(FVector::ZeroVector);
		// SetRelativeRotation(FRotator::ZeroRotator);
		// SetRelativeScale3D(FVector::OneVector);
		AnimationDone.Broadcast();
		SetComponentTickEnabled(false);
	}

	float GetCurveValue(FRuntimeFloatCurve Curve, float Time, float DefaultValue) const
	{
		if(Curve.NumKeys == 0)
			return DefaultValue;

		return Curve.GetFloatValue(Time);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float TimeSinceStart = Math::Clamp(Time::GameTimeSeconds - StartTime, 0, Duration);

		if(bReversed)
			TimeSinceStart = Duration - TimeSinceStart;

		const float XScale = GetCurveValue(XScaleCurve, TimeSinceStart, 1);
		const float YScale = GetCurveValue(YScaleCurve, TimeSinceStart, 1);
		const float ZScale = GetCurveValue(ZScaleCurve, TimeSinceStart, 1);

		const float HeightOffsetAlpha = GetCurveValue(ZOffsetCurve, TimeSinceStart, 0);
		const float Yaw = GetCurveValue(YawCurve, TimeSinceStart, 0);

		SetRelativeScale3D(FVector(XScale, YScale, ZScale));
		SetRelativeLocation(FVector::UpVector * HeightOffsetAlpha * HeightOffsetMax);
		SetRelativeRotation(FRotator::MakeFromEuler(FVector::UpVector * Yaw * 360));
	}
};