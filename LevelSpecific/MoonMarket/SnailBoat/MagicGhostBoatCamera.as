class AMagicGhostBoatCamera : AHazeCameraActor
{
	UPROPERTY(OverrideComponent = Camera, ShowOnActor)  
    UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"MagicGhostBoatCameraCapability");

	UPROPERTY()
	FRuntimeFloatCurve FocusTargetCurve;

	UPROPERTY(EditInstanceOnly)
	AActor FocusActor;

	UPROPERTY(EditAnywhere)
	float BackOffset = 1300.0;

	UPROPERTY(EditAnywhere)
	float UpOffset = 420.0;

	UPROPERTY(EditAnywhere)
	float TargetRiseAmount = 4000.0;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve TargetRiseCurve;
	default TargetRiseCurve.AddDefaultKey(0, 0);
	default TargetRiseCurve.AddDefaultKey(0.6, 0.2);
	default TargetRiseCurve.AddDefaultKey(1.0, 1.0);

	bool bRunCameraBackOffsetBlend;

	private float SplineAlongAlpha;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void StartBackOffsetBlend()
	{
		bRunCameraBackOffsetBlend = true;
	}

	void SetAlphaValue(float NewValue)
	{
		SplineAlongAlpha = NewValue;
	}

	float GetSplineAlongAlpha() const
	{
		return TargetRiseCurve.GetFloatValue(SplineAlongAlpha);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugLine(FocusActor.ActorLocation, FocusActor.ActorLocation + FVector::UpVector * TargetRiseAmount, FLinearColor::Red, 20.0);
	}
#endif
};