
class UTeenDragonTailGeckoClimbBlend : UHazeCameraViewPointBlendType
{
	UFUNCTION(BlueprintOverride)
	bool BlendView(
		FHazeViewBlendInfo& SourceView,
		FHazeViewBlendInfo TargetView,
		FHazeViewBlendInfo& OutCurrentView,
		FHazeCameraViewPointBlendInfo BlendInfo,
		FHazeCameraViewPointBlendAdvanced AdvancedInfo) const
	{
		const float BlendFraction = GetBlendAlpha(BlendInfo);
		OutCurrentView = SourceView.Blend(TargetView, BlendFraction);

		{
		 	float TranslationAlpha = Math::EaseInOut(0, 1, BlendFraction, 1.5);
		 	OutCurrentView.Location = Math::Lerp(SourceView.Location, TargetView.Location, TranslationAlpha);
		}

		{
			float RotationAlpha = Math::EaseInOut(0, 1, BlendFraction, 1);
			OutCurrentView.Rotation = Math::LerpShortestPath(SourceView.Rotation, TargetView.Rotation, RotationAlpha);
		}

		// Debug
		#if !RELEASE
		auto TemporalLog = GetCameraTemporalLog();
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Type", this);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Target Time", BlendInfo.BlendTime);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};Blend Alpha", f"{BlendFraction :.3}");
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};View Location", OutCurrentView.Location);
		TemporalLog.Value(f"{CameraDebug::CategoryBlend};View Rotation", OutCurrentView.Rotation);
		#endif

		// We need to blend in the entire camera before we finish
		return BlendFraction < 1 - KINDA_SMALL_NUMBER;
	}

	private float GetBlendAlpha(FHazeCameraViewPointBlendInfo BlendInfo) const
	{	
		// Tweak the alpha here
		return BlendInfo.BlendAlpha;
	}
}