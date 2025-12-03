
enum ECameraDefaultBlendVelocityAlphaType
{
	AlphaType,
	Linear,
	EaseIn,
	EaseOut,
	EaseInOut,
	Accelerated
}

/**
 * The default blend asset has settings for blending using accelerated an normal blend
 * This blend will start from the source view and blend to the target view over the blend duration using 'AlphaType'
 * It can be customized to include the camera velocity it had when starting the blend
 */
class UCameraDefaultBlend : UHazeCameraViewPointBlendType
{
	// Defines how the alpha will be used.
	UPROPERTY()
	ECameraBlendAlphaType AlphaType = ECameraBlendAlphaType::Accelerated;

	UPROPERTY(Meta = (EditCondition = "AlphaType == ECameraBlendAlphaType::Curve", EditConditionHides))
	FRuntimeFloatCurve BlendCurve;
	default BlendCurve.AddDefaultKey(0, 0);
	default BlendCurve.AddDefaultKey(1, 1);

	/** If true, the camera will maintain the velocity it had when started the blend
	 * making the location move in the direction it had for a little while
	*/
	UPROPERTY()
	bool bIncludeLocationVelocity = false;

	UPROPERTY(meta = (EditCondition="bIncludeLocationVelocity && bLockSourceViewLocation"))
	ECameraDefaultBlendVelocityAlphaType LocationVelocityCustomBlendType = ECameraDefaultBlendVelocityAlphaType::AlphaType;

	/** If true, the camera will maintain the velocity it had when started the blend 
	 * making it continue to rotate towards the rotation the last camera wanted for a while
	*/ 
	UPROPERTY()
	bool bIncludeRotationVelocity = false;

	UPROPERTY(meta = (EditCondition="bIncludeRotationVelocity && bLockSourceViewRotation"))
	ECameraDefaultBlendVelocityAlphaType RotationVelocityCustomBlendType = ECameraDefaultBlendVelocityAlphaType::AlphaType;

	/** During this time, the view location is not blended towards the new view location
	 * Instead, the view location is only changed using the the view velocity
	 * The value is 0 -> 1 where 1 is the entire blend time
	 */ 
	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float LockViewLocationDuringDurationPercentage = 0;

	/** During this time, the view rotation is not blended towards the new view location
	 * Instead, the view location is only changed using the the view velocity
	 * The value is 0 -> 1 where 1 is the entire blend time
	 */ 
	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float LockViewRotationDuringDurationPercentage = 0;

	// Used to make some alpha curves steeper
	UPROPERTY(AdvancedDisplay)
	float Exponential = 2;

	// Clamp used so we can't overshoot to much
	UPROPERTY(AdvancedDisplay)
	float ClampVelocitySize = -1;

	/** 
	 * The source view needs to follow the target rotation delta or we will overshoot if the target
	 * rotates over 180 degree during the blend.
	*/
	UPROPERTY(AdvancedDisplay)
	bool bLockSourceViewRotation = true;

	/**
	 * If you want to update the source view with the current cameras transform from the get go
	 * you can turn this of to make the blend move faster into a moving camera
	 */
	UPROPERTY(AdvancedDisplay)
	bool bLockSourceViewLocation = true;

	private ECameraBlendAlphaType GetBlendAlphaTypeFromVelocityAlphaType(ECameraDefaultBlendVelocityAlphaType Type) const
	{
		if(Type == ECameraDefaultBlendVelocityAlphaType::AlphaType)
			return AlphaType;
		if(Type == ECameraDefaultBlendVelocityAlphaType::Linear)
			return ECameraBlendAlphaType::Linear;
		if(Type == ECameraDefaultBlendVelocityAlphaType::Accelerated)
			return ECameraBlendAlphaType::Accelerated;
		if(Type == ECameraDefaultBlendVelocityAlphaType::EaseIn)
			return ECameraBlendAlphaType::EaseIn;
		if(Type == ECameraDefaultBlendVelocityAlphaType::EaseOut)
			return ECameraBlendAlphaType::EaseOut;
		if(Type == ECameraDefaultBlendVelocityAlphaType::EaseInOut)
			return ECameraBlendAlphaType::EaseInOut;

		// Not implemented
		devCheck(false);
		return AlphaType;
	}

	UFUNCTION(BlueprintOverride)
	bool BlendView(
		FHazeViewBlendInfo& SourceView,
		FHazeViewBlendInfo TargetView,
		FHazeViewBlendInfo& OutCurrentView,
		FHazeCameraViewPointBlendInfo BlendInfo,
		FHazeCameraViewPointBlendAdvanced AdvancedInfo) const
	{
		const float BlendFraction = CameraBlend::GetBlendAlpha(AlphaType, BlendInfo, BlendCurve, Exponential);

		FHazeViewBlendInfo SourceDeltaView;
		SourceDeltaView.ApplyBlendWeight(0);

		{
			FHazeViewBlendInfo Diff;
			AdvancedInfo.PreviousTargetView.GenerateViewDiff(TargetView, Diff);
			
			if(!bLockSourceViewRotation)
				SourceDeltaView.Rotation = Diff.Rotation;

			if(!bLockSourceViewLocation)
				SourceDeltaView.Location = Diff.Location;
		}
		
		SourceView.AddWeightedViewInfo(SourceDeltaView, 1);

		OutCurrentView = SourceView.Blend(TargetView, BlendFraction);

		FVector LocationOffset = FVector::ZeroVector;
		FRotator RotationOffset = FRotator::ZeroRotator;

		// View Location
		if(LockViewLocationDuringDurationPercentage > SMALL_NUMBER && bLockSourceViewLocation)
		{
			const float SmoothBlendVelocityTime = Math::Clamp(LockViewLocationDuringDurationPercentage, 0.0, 1.0);
			float OffsetBlendFraction = Math::Max(BlendFraction - SmoothBlendVelocityTime, 0.0) / (1 - SmoothBlendVelocityTime);
			
			// Lerp the location with the applied delay
			OutCurrentView.Location = Math::Lerp(SourceView.Location, TargetView.Location, OffsetBlendFraction);
			
			OffsetBlendFraction = 1 - (CameraBlend::GetBlendAlpha(GetBlendAlphaTypeFromVelocityAlphaType(LocationVelocityCustomBlendType), BlendInfo, BlendCurve, Exponential) * OffsetBlendFraction);
			LocationOffset = GetLocationOffset(AdvancedInfo.ViewVelocity, BlendInfo.ActiveTime) * OffsetBlendFraction;
		}
		else
		{
			const float OffsetBlendFraction = 1 - CameraBlend::GetBlendAlpha(GetBlendAlphaTypeFromVelocityAlphaType(LocationVelocityCustomBlendType), BlendInfo, BlendCurve, Exponential);
			LocationOffset = GetLocationOffset(AdvancedInfo.ViewVelocity, BlendInfo.ActiveTime) * OffsetBlendFraction;
		}

		// View Rotation
		if(LockViewRotationDuringDurationPercentage > SMALL_NUMBER && bLockSourceViewRotation)
		{
			const float SmoothBlendVelocityTime = Math::Clamp(LockViewRotationDuringDurationPercentage, 0.0, 1.0);
			float OffsetBlendFraction = Math::Max(BlendFraction - SmoothBlendVelocityTime, 0.0) / (1 - SmoothBlendVelocityTime);
			
			// Lerp the rotation with the applied delay
			OutCurrentView.Rotation = Math::LerpShortestPath(SourceView.Rotation, TargetView.Rotation, OffsetBlendFraction);
			
			OffsetBlendFraction = 1 - (CameraBlend::GetBlendAlpha(GetBlendAlphaTypeFromVelocityAlphaType(RotationVelocityCustomBlendType), BlendInfo, BlendCurve, Exponential) * OffsetBlendFraction);
			RotationOffset = GetRotationOffset(AdvancedInfo.ViewAngularVelocity, BlendInfo.ActiveTime) * OffsetBlendFraction;
		}
		else
		{
			const float OffsetBlendFraction = 1 - CameraBlend::GetBlendAlpha(GetBlendAlphaTypeFromVelocityAlphaType(RotationVelocityCustomBlendType), BlendInfo, BlendCurve, Exponential);
			RotationOffset = GetRotationOffset(AdvancedInfo.ViewAngularVelocity, BlendInfo.ActiveTime) * OffsetBlendFraction;
		}

		// Blend the view and apply the offsets
		OutCurrentView.Location += LocationOffset;
		OutCurrentView.Rotation += RotationOffset;

		// Debug
		#if !RELEASE
		auto TemporalLog = GetCameraTemporalLog();
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Type", this);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Target Time", BlendInfo.BlendTime);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Active Time", BlendInfo.ActiveTime);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Alpha", f"{BlendFraction :.3}");
		TemporalLog.CompactValue(f"{CameraDebug::CategoryBlend};Velocity", AdvancedInfo.ViewVelocity);
		TemporalLog.CompactValue(f"{CameraDebug::CategoryBlend};AngularVelocity", AdvancedInfo.ViewAngularVelocity);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Source Location", SourceView.Location);
		TemporalLog.CompactValue(f"{CameraDebug::CategoryBlend};Source Rotation", SourceView.Rotation);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Target Location", TargetView.Location);
		TemporalLog.CompactValue(f"{CameraDebug::CategoryBlend};Target Rotation", TargetView.Rotation);

		TemporalLog.DirectionalArrow(f"{CameraDebug::CategoryBlend};Source Rotation Dir", OutCurrentView.Location, SourceView.Rotation.ForwardVector * 1000, Color = FLinearColor::Blue);
		TemporalLog.DirectionalArrow(f"{CameraDebug::CategoryBlend};Target Rotation Dir", TargetView.Location, TargetView.Rotation.ForwardVector * 1000, Color = FLinearColor::DPink);
		TemporalLog.DirectionalArrow(f"{CameraDebug::CategoryBlend};Prev Target Rotation Dir", AdvancedInfo.PreviousTargetView.Location, AdvancedInfo.PreviousTargetView.Rotation.ForwardVector * 1000, Color = FLinearColor::Teal);
		#endif

		// We need to blend in the entire camera before we finish
		return BlendFraction < 1 - KINDA_SMALL_NUMBER;
	}

	private FVector GetLocationOffset(FVector ViewVelocity, float ActiveTime) const
	{
		FVector Offset = FVector::ZeroVector;

		// Clamped to the camera is not getting away to much
		if(bIncludeLocationVelocity)
		{
			if(ClampVelocitySize > 0)
				Offset += ViewVelocity.GetClampedToMaxSize(ClampVelocitySize) * ActiveTime;
			else
				Offset += ViewVelocity * ActiveTime;
		}
			
		return Offset;
	}

	private FRotator GetRotationOffset(FRotator ViewAngularVelocity, float ActiveTime) const
	{
		FRotator Offset = FRotator::ZeroRotator;

		if(bIncludeRotationVelocity)
			Offset += ViewAngularVelocity * ActiveTime;
		
		return Offset;
	}

}