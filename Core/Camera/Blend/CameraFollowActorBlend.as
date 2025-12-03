




/**
 * 
 */
class UCameraFollowActorBlend : UHazeCameraViewPointBlendType
{
	// Defines how the alpha will be used.
	UPROPERTY()
	ECameraBlendAlphaType AlphaType = ECameraBlendAlphaType::Accelerated;

	UPROPERTY(Meta = (EditCondition = "AlphaType == ECameraBlendAlphaType::Curve", EditConditionHides))
	FRuntimeFloatCurve BlendCurve;
	default BlendCurve.AddDefaultKey(0, 0);
	default BlendCurve.AddDefaultKey(1, 1);

	/** If true, the camera will maintain the velocity it had when started the blend 
	 * making it continue to rotate towards the rotation the last camera wanted for a while
	*/ 
	UPROPERTY()
	bool bIncludeRotationVelocity = false;

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

	UFUNCTION(BlueprintOverride)
	bool BlendView(
		FHazeViewBlendInfo& SourceView,
		FHazeViewBlendInfo TargetView,
		FHazeViewBlendInfo& OutCurrentView,
		FHazeCameraViewPointBlendInfo BlendInfo,
		FHazeCameraViewPointBlendAdvanced AdvancedInfo) const
	{
		const float BlendFraction = CameraBlend::GetBlendAlpha(AlphaType, BlendInfo, BlendCurve, Exponential);
		OutCurrentView = SourceView.Blend(TargetView, BlendFraction);

		FVector LocationOffset = FVector::ZeroVector;
		FRotator RotationOffset = FRotator::ZeroRotator;

		// View Location
		{
			FVector SourceLocationOffset = SourceView.Location - AdvancedInfo.SourceUserTransform.Location;
			FVector TargetLocationOffset = TargetView.Location - AdvancedInfo.CurrentUserTransform.Location;
	
			float OffsetBlendFraction = BlendFraction;
			if(LockViewLocationDuringDurationPercentage > SMALL_NUMBER)
			{
				const float SmoothBlendVelocityTime = Math::Clamp(LockViewLocationDuringDurationPercentage, 0.0, 1.0);
				OffsetBlendFraction = Math::Max(BlendFraction - SmoothBlendVelocityTime, 0.0) / (1 - SmoothBlendVelocityTime);
			}

			LocationOffset = Math::Lerp(SourceLocationOffset, TargetLocationOffset, OffsetBlendFraction);
			OutCurrentView.Location = AdvancedInfo.CurrentUserTransform.Location;
			OutCurrentView.Location += LocationOffset;
		}

		// View Rotation
		if(LockViewRotationDuringDurationPercentage > SMALL_NUMBER)
		{
			const float SmoothBlendVelocityTime = Math::Clamp(LockViewRotationDuringDurationPercentage, 0.0, 1.0);
			float OffsetBlendFraction = Math::Max(BlendFraction - SmoothBlendVelocityTime, 0.0) / (1 - SmoothBlendVelocityTime);
			
			// Lerp the location with the applied delay
			OutCurrentView.Rotation = Math::LerpShortestPath(SourceView.Rotation, TargetView.Rotation, OffsetBlendFraction);
			
			OffsetBlendFraction = Math::EaseOut(0, 1, 1 - OffsetBlendFraction, Exponential);
			RotationOffset = GetRotationOffset(AdvancedInfo.ViewAngularVelocity, BlendInfo.ActiveTime) * OffsetBlendFraction;
		}
		else
		{
			const float OffsetBlendFraction = Math::EaseOut(0, 1, 1 - BlendFraction, Exponential);
			RotationOffset = GetRotationOffset(AdvancedInfo.ViewAngularVelocity, BlendInfo.ActiveTime) * OffsetBlendFraction;
		}

		// Blend the view and apply the offsets
		OutCurrentView.Rotation += RotationOffset;

		// Debug
		#if !RELEASE
		auto TemporalLog = GetCameraTemporalLog();
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Type", this);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Target Time", BlendInfo.BlendTime);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Active Time", BlendInfo.ActiveTime);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Alpha", f"{BlendFraction :.3}");
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};View Location", OutCurrentView.Location);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};View Rotation", OutCurrentView.Rotation);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};User Location", AdvancedInfo.CurrentUserTransform.Location);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Location Offset", LocationOffset);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Rotation Offset", RotationOffset);
		TemporalLog.CompactValue(f"{CameraDebug::CategoryBlend};AngularVelocity", AdvancedInfo.ViewAngularVelocity);
		#endif

		// We need to blend in the entire camera before we finish
		return BlendFraction < 1 - KINDA_SMALL_NUMBER;
	}

	private FRotator GetRotationOffset(FRotator ViewAngularVelocity, float ActiveTime) const
	{
		FRotator Offset = FRotator::ZeroRotator;

		if(bIncludeRotationVelocity)
			Offset += ViewAngularVelocity * ActiveTime;
		
		return Offset;
	}

}