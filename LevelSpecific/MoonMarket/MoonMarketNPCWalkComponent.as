class UMoonMarketNPCWalkComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve SlowdownCurve;

	UPROPERTY(EditInstanceOnly)
	ASplineActor WalkSpline;

	UPROPERTY(EditDefaultsOnly)
	float WalkSpeed = 140;

	FSplinePosition CurrentSplinePosition;

	UMoonMarketNPCIdleSplinePoint PreviousIdlePoint;
	UMoonMarketNPCIdleSplinePoint NextIdlePoint;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve JumpCurve;

	bool bIdling = false;

	bool bActivated = true;

	float LastStunTime = 0;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetNextIdlePoint();
	}

	void SetNextIdlePoint()
	{
		if(WalkSpline == nullptr)
			return;
		
		const float DistAlongSpline = CurrentSplinePosition.CurrentSplineDistance;
		TOptional<FAlongSplineComponentData> AlongSplineCompData = WalkSpline.Spline.FindNextComponentAlongSpline(UMoonMarketNPCIdleSplinePoint, false, DistAlongSpline);
		if(AlongSplineCompData.IsSet())
			NextIdlePoint = Cast<UMoonMarketNPCIdleSplinePoint>(AlongSplineCompData.GetValue().Component);

		AlongSplineCompData = WalkSpline.Spline.FindPreviousComponentAlongSpline(UMoonMarketNPCIdleSplinePoint, false, DistAlongSpline);
		if(AlongSplineCompData.IsSet())
			PreviousIdlePoint = Cast<UMoonMarketNPCIdleSplinePoint>(AlongSplineCompData.GetValue().Component);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if(WalkSpline != nullptr)
		{
			Debug::DrawDebugPoint(Owner.ActorLocation, 50, FLinearColor::Green, bDrawInForeground = true);
			WalkSpline.Spline.DrawDebug(100, FLinearColor::Green, 10);
		}
	}
#endif
};