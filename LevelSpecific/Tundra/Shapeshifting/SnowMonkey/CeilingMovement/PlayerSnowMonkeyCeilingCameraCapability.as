class UTundraPlayerSnowMonkeyCeilingCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyCeilingClimb);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkey);

	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;
	UTundraPlayerSnowMonkeyCeilingClimbDataComponent CeilingClimbDataComp;
	UPlayerMovementComponent MoveComp;
	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UTundraPlayerSnowMonkeySettings Settings;

	UTundraPlayerSnowMonkeyCeilingClimbComponent PreviousCeiling;
	UTundraPlayerSnowMonkeyCeilingClimbComponent CurrentCeiling;
	float TimeOfSetCeiling;
	float PreviousDistance;
	float CurrentDistance;
	bool bWithinBoundsOfACeiling;
	float Alpha;
	bool bPivotOffsetting = false;
	float ShapeshiftingLerpAlpha;

	const float BlendTimeBetweenCeilings = 0.3;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		CeilingClimbDataComp = UTundraPlayerSnowMonkeyCeilingClimbDataComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		Settings = UTundraPlayerSnowMonkeySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(SnowMonkeyComp.CurrentCeilingComponent == nullptr)
		{
			FTundraPlayerSnowMonkeyCeilingData NewCeiling;
			bWithinBoundsOfACeiling = CeilingClimbDataComp.IsSnowMonkeyWithinDistanceToCeiling(NewCeiling, Settings.CeilingCameraSettingsAlphaBlendDistance);

			if(NewCeiling.ClimbComp != nullptr || !IsActive())
			{
				SetCurrentCeiling(NewCeiling.ClimbComp);
			}
		}
		else
		{
			SetCurrentCeiling(SnowMonkeyComp.CurrentCeilingComponent);
		}

		float StartDistance = Settings.CeilingCameraSettingsAlphaBlendDistance;

		if(CurrentCeiling != nullptr)
		{
			FTundraPlayerSnowMonkeyCeilingData Data = CurrentCeiling.GetCeilingData();
			CurrentDistance = Data.GetDistanceToCeiling(TopOfPlayerCapsule);
			float TargetAlpha = Math::GetMappedRangeValueClamped(FVector2D(StartDistance, 0.0), FVector2D(0.0, 1.0), CurrentDistance);
			if(TargetAlpha == 0.0)
				PreviousCeiling = nullptr;

			// if(SnowMonkeyComp.CurrentCeilingComponent != nullptr)
			// 	CurrentDistance = 0.0;

			// float TimeSince = Time::GetGameTimeSince(TimeOfSetCeiling);
			// if(PreviousCeiling != nullptr && TimeSince < BlendTimeBetweenCeilings)
			// {
			// 	float BetweenCeilingAlpha = TimeSince / BlendTimeBetweenCeilings;
			// 	BetweenCeilingAlpha = Math::Saturate(BetweenCeilingAlpha);
			// 	BetweenCeilingAlpha = Math::EaseInOut(0.0, 1.0, BetweenCeilingAlpha, 2.0);
			// 	CurrentDistance = Math::Lerp(PreviousDistance, CurrentDistance, BetweenCeilingAlpha);
			// }
#if EDITOR
			FVector Point = Data.GetClosestPointOnCeiling(TopOfPlayerCapsule);
			TEMPORAL_LOG(this)
			.Point("Point", Point, 10.f, FLinearColor::Red)
			.Value("Current Distance", CurrentDistance)
			;
#endif
		}

		float TargetAlpha = Math::GetMappedRangeValueClamped(FVector2D(StartDistance, 0.0), FVector2D(0.0, 1.0), CurrentDistance);
		float TimeSinceShapeshift = Time::GetGameTimeSince(ShapeshiftingComp.TimeOfLastShapeshift);
		ShapeshiftingLerpAlpha = Math::Saturate(TimeSinceShapeshift / 0.3);
		if(SnowMonkeyComp.bForceEnteredCurrentCeilingComp)
			ShapeshiftingLerpAlpha = 1.0;

		Alpha = Math::Lerp(0.0, TargetAlpha, ShapeshiftingLerpAlpha);
#if EDITOR
		TEMPORAL_LOG(this).Value("Alpha", Alpha);
#endif
	}

	void SetCurrentCeiling(UTundraPlayerSnowMonkeyCeilingClimbComponent Ceiling)
	{
		if(Ceiling == CurrentCeiling)
			return;

		PreviousDistance = CurrentDistance;
		PreviousCeiling = CurrentCeiling;
		CurrentCeiling = Ceiling;
		TimeOfSetCeiling = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!bWithinBoundsOfACeiling)
			return false;

		// If we are in a ceiling climb atm, always have camera blended in with alpha: 1
		if(SnowMonkeyComp.CurrentCeilingComponent != nullptr)
			return true;

		// A negative vertical distance means the monkey is above the ceiling
		if(CurrentDistance < 0.0)
			return false;

		if(Alpha <= 0.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// If we are in a ceiling climb atm, always have camera blended in with alpha: 1
		if(SnowMonkeyComp.CurrentCeilingComponent != nullptr)
			return false;

		// A negative vertical distance means the monkey is above the ceiling
		if(CurrentDistance < 0.0)
			return true;

		if(Alpha <= 0.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyCameraSettings(SnowMonkeyComp.CeilingCameraSettings, 0.0, this, SubPriority = 75);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, ShapeshiftingComp.CurrentShapeType != ETundraShapeshiftShape::Big ? 2.0 : 0.5);
		Player.ClearCameraSettingsByInstigator(FName("CeilingCameraPivotOffset"), 2.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.ApplyManualFractionToCameraSettings(Alpha, this);
		
		float Distance = GetPivotOffsetDistance();
		if(Distance > 0.0)
		{
			if(!bPivotOffsetting)
			{
				bPivotOffsetting = true;

			}
		}
		else
		{
			if(bPivotOffsetting)
			{
				bPivotOffsetting = false;

			}
		}

		Distance *= Math::EaseInOut(0.0, 1.0, ShapeshiftingLerpAlpha, 2.0);
		UCameraSettings::GetSettings(Player).WorldPivotOffset.Apply(FVector::DownVector * Distance, FName("CeilingCameraPivotOffset"), SubPriority = 75);
	}

	float GetPivotOffsetDistance()
	{
		float Distance = Settings.CeilingCameraSettingsPivotOffsetDistance - CurrentDistance;
		if(Distance < 0.0)
			Distance = 0.0;

		return Distance;
	}

	FVector GetTopOfPlayerCapsule() const property
	{
		return Player.ActorLocation + FVector::UpVector * TundraShapeshiftingStatics::SnowMonkeyCollisionSize.Y * 2.0;
	}
}