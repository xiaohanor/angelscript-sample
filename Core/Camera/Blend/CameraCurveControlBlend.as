/**
 * This blend can control location and rotation independently through curves.
 * Blending is done when both curves have reached a float value of 1.0
 */
class UCameraCurveControlBlend : UHazeCameraViewPointBlendType
{
	/**
	 * How fast location blends.
	 * Must be a value between 0 and 1
	 * MUST end at 1.0
	 */
	UPROPERTY()
	FRuntimeFloatCurve LocationAlphaCurve;

	/**
	 * How fast rotation blends.
	 * Must be a value between 0 and 1
	 * MUST end at 1.0
	 */
	UPROPERTY()
	FRuntimeFloatCurve RotationAlphaCurve;

	// Return true whilst blending
	UFUNCTION(BlueprintOverride)
	bool BlendView(FHazeViewBlendInfo& SourceView, FHazeViewBlendInfo TargetView,
				   FHazeViewBlendInfo& OutCurrentView, FHazeCameraViewPointBlendInfo BlendInfo,
				   FHazeCameraViewPointBlendAdvanced AdvancedInfo) const
	{
		ValidateCurve(LocationAlphaCurve, "LocationCurve");
		ValidateCurve(RotationAlphaCurve, "RotationCurve");

		const float BlendAlpha = BlendInfo.BlendAlpha;

		const float LocationBlendAlpha = LocationAlphaCurve.GetFloatValue(BlendAlpha, BlendAlpha);
		const float RotationBlendAlpha = RotationAlphaCurve.GetFloatValue(BlendAlpha, BlendAlpha);

		OutCurrentView.Location = Math::Lerp(SourceView.Location, TargetView.Location, LocationBlendAlpha);
		OutCurrentView.Rotation = FQuat::Slerp(SourceView.Rotation.Quaternion(), TargetView.Rotation.Quaternion(), RotationBlendAlpha).Rotator();

#if !RELEASE
		auto TemporalLog = GetCameraTemporalLog();
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Type", this);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Target Time", BlendInfo.BlendTime);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Alpha", f"{BlendAlpha :.3}");
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Location Blend Alpha", f"{LocationBlendAlpha :.3}");
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Rotation Blend Alpha", f"{RotationBlendAlpha :.3}");
#endif

		if (LocationBlendAlpha < 1.0)
			return true;

		if (RotationBlendAlpha < 1.0)
			return true;

		return false;
	}

	void ValidateCurve(FRuntimeFloatCurve FloatCurve, FString CurveName) const
	{
		float MinTime = 0, MaxTime = 0;
		FloatCurve.GetTimeRange(MinTime, MaxTime);

		devCheck(MinTime >= 0, f"CameraCurveControlBlend::{CurveName} - MinTime ({MinTime}) must be greater or equal than 0");
		devCheck(MaxTime == 1.0, f"CameraCurveControlBlend::{CurveName} - MaxTime ({MaxTime}) must be 1.0");

		float MinValue = 0, MaxValue = 0;
		FloatCurve.GetValueRange(MinValue, MaxValue);

		devCheck(MinValue >= 0.0, f"CameraCurveControlBlend::{CurveName} - MinValue ({MinValue}) must be greater or equal than 0");
		devCheck(MaxValue == 1.0, f"CameraCurveControlBlend::{CurveName} - MaxValue ({MaxValue}) must be 1.0");
	}
}