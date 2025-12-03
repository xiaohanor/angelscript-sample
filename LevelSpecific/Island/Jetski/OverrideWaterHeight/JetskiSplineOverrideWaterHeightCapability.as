class UJetskiSplineOverrideWaterHeightCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	AJetski Jetski;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Jetski.JetskiSpline == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Jetski.JetskiSpline == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
#if !RELEASE
		TOptional<FAlongSplineComponentData> FoundComponent = Jetski.JetskiSpline.Spline.FindPreviousComponentAlongSpline(
			UJetskiSplineOverrideWaterHeightComponent,
			false,
			Jetski.GetDistanceAlongSpline()
		);

		if(FoundComponent.IsSet())
		{
			auto OverrideComp = Cast<UJetskiSplineOverrideWaterHeightComponent>(FoundComponent.Value.Component);

			TemporalLog.Value("OverrideComp", OverrideComp);
			if(OverrideComp != nullptr)
			{
				TemporalLog.Value("bOverride", OverrideComp.bOverride);

				if(OverrideComp.bOverride)
					TemporalLog.Value("WaterHeight", OverrideComp.GetWaterHeight());
			}
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TOptional<FAlongSplineComponentData> FoundComponent = Jetski.JetskiSpline.Spline.FindPreviousComponentAlongSpline(
			UJetskiSplineOverrideWaterHeightComponent,
			false,
			Jetski.GetDistanceAlongSpline()
		);

		UJetskiSplineOverrideWaterHeightComponent OverrideComp;
		if(FoundComponent.IsSet())
			OverrideComp = Cast<UJetskiSplineOverrideWaterHeightComponent>(FoundComponent.Value.Component);

		if(OverrideComp != nullptr)
		{
			if(OverrideComp.bOverride)
				Jetski.ApplyWaterHeightOverride(OverrideComp.GetWaterHeight(), this, EInstigatePriority::Low);
			else
				Jetski.ClearWaterHeightOverride(this);
		}
		else
		{
			Jetski.ClearWaterHeightOverride(this);
		}
	}
};