/**
 * How we determine where the pivot point that we are orbiting around is.
 */
enum ECameraOrbitBlendPivotPointType
{
	/**
	 * Always orbit around the camera user, usually the player.
	 */
	CameraUser,

	/**
	 * Pivot around the point that both the Source and Target are looking at.
	 * If the source and target are not facing the same direction, we will compromise and pick a point at the plane defined by the source location and target direction.
	 */
	SourceTargetDirectionIntersection,

	/**
	 * Specify manually what to orbit around.
	 * FB TODO: How do we actually do this? Is there any way to get the data to the blend?
	 */
	//Manual,
};

// enum ECameraOrbitBlendDirection
// {
// 	Closest,
// 	PreferClockwise,
// 	PreferCounterClockwise,
// 	ForceClockwise,
// 	ForceCounterClockwise,
// };

/**
 * This blend will perform an orbiting move from the source to the target instead of moving the shortest path.
 * The pivot point is automatically determined to be the axis of the source and target view direction vertical plane intersection
 * (AKA the point both views are pointing towards)
 */
class UCameraOrbitBlend : UHazeCameraViewPointBlendType
{
	/**
	 * Defines how the alpha will be used
	 */
	UPROPERTY(Category = "Blend")
	ECameraBlendAlphaType AlphaType = ECameraBlendAlphaType::EaseInOut;

	UPROPERTY(Category = "Blend", Meta = (EditCondition = "AlphaType == ECameraBlendAlphaType::Curve", EditConditionHides))
	FRuntimeFloatCurve BlendCurve;
	default BlendCurve.AddDefaultKey(0, 0);
	default BlendCurve.AddDefaultKey(1, 1);

	/**
	 * Used to make some alpha curves steeper
	 */
	UPROPERTY(Category = "Blend", AdvancedDisplay)
	float Exponential = 2;

	UPROPERTY(Category = "Orbit")
	ECameraOrbitBlendPivotPointType PivotPointType = ECameraOrbitBlendPivotPointType::CameraUser;

	/**
	* I haven't implemented this yet, but it would be very nice to have
	*/
	// UPROPERTY(Category = "Orbit")
	// ECameraOrbitBlendDirection BlendDirection = ECameraOrbitBlendDirection::Closest;

	UFUNCTION(BlueprintOverride)
	bool BlendView(
		FHazeViewBlendInfo& SourceView,
		FHazeViewBlendInfo TargetView,
		FHazeViewBlendInfo& OutCurrentView,
		FHazeCameraViewPointBlendInfo BlendInfo,
		FHazeCameraViewPointBlendAdvanced AdvancedInfo) const
	{
		const float BlendFraction = CameraBlend::GetBlendAlpha(AlphaType, BlendInfo, BlendCurve, Exponential);

		// Perform regular blend for FOV and such
		OutCurrentView = SourceView.Blend(TargetView, BlendFraction);

		// Below is a hacky fix since SourceView will actually be the source view from one frame before the blend started.
		// This would've lead to a snap at super high velocities unless we do the below. The ideal fix is to update the source view just before the blend starts but that is too late to fix now.
		if(Time::FrameNumber - 1 <= BlendInfo.ActivationFrame)
		{
			SourceView.Location += SourceView.ViewVelocity * AdvancedInfo.DeltaTime;
		}

		// Just do a regular blend if we can't blend
		if(!CanBlend(SourceView, TargetView))
			return true;

		// Figure out where we originally where when the orbit starts, relative to the pivot
		FVector SourceLocation = SourceView.Location;

		if(PivotPointType == ECameraOrbitBlendPivotPointType::CameraUser)
		{
			// Make relative to the current user
			FVector RelativeToUserSourceLocation = SourceLocation - AdvancedInfo.SourceUserTransform.Location;
			SourceLocation = AdvancedInfo.CurrentUserTransform.Location + RelativeToUserSourceLocation;
		}

		const FVector PivotPoint = GetPivotPoint(
			SourceView,
			TargetView,
			AdvancedInfo
		);

		const FTransform PivotSourceTransform = FTransform(SourceView.Rotation, PivotPoint);
		const FVector SourceRelativeLocation = PivotSourceTransform.InverseTransformPositionNoScale(SourceLocation);

		// Figure out where we want to go when the orbit ends, relative to the pivot
		const FTransform PivotTargetTransform = FTransform(TargetView.Rotation, PivotPoint);
		const FVector TargetRelativeLocation = PivotTargetTransform.InverseTransformPositionNoScale(TargetView.Location);

		// Lerp our relative location over the blend
		const FVector RelativeToPivotLocation = Math::Lerp(
			SourceRelativeLocation,
			TargetRelativeLocation,
			BlendFraction
		);

		// Apply the pivot transform to our location
		// The regular camera blend will take care of blending the pivot rotation
		const FTransform PivotCurrentTransform = FTransform(OutCurrentView.Rotation, PivotPoint);
		OutCurrentView.Location = PivotCurrentTransform.TransformPositionNoScale(RelativeToPivotLocation);

#if !RELEASE
		FTemporalLog BlendTemporalLog = GetCameraTemporalLog().Section("Blend", 35);
		BlendTemporalLog.Value("Blend Type", this);
		BlendTemporalLog.Value("Blend Target Time", BlendInfo.BlendTime);
		BlendTemporalLog.Value("Blend Active Time", BlendInfo.ActiveTime);
		BlendTemporalLog.Value("Blend Alpha", f"{BlendFraction :.3}");

		BlendTemporalLog.Transform("Source User Tranform", AdvancedInfo.SourceUserTransform);
		BlendTemporalLog.Transform("Current User Tranform", AdvancedInfo.CurrentUserTransform);

		BlendTemporalLog.Transform("Source Tranform", ConvertViewToTransform(SourceView));
		BlendTemporalLog.Transform("Current Tranform", ConvertViewToTransform(OutCurrentView));
		BlendTemporalLog.Transform("Target Tranform", ConvertViewToTransform(TargetView));

		FTemporalLog OrbitTemporalLog = BlendTemporalLog.Section("Orbit");
		OrbitTemporalLog.Point("Orbit;Pivot Point", PivotPoint, 100);
		OrbitTemporalLog.Transform("Pivot Source Transform", PivotSourceTransform, 500, 50);
		OrbitTemporalLog.Transform("Pivot Target Transform", FTransform(TargetView.Rotation, PivotPoint), 500, 50);
		OrbitTemporalLog.Transform("Pivot Current Transform", PivotCurrentTransform, 500, 50);

		OrbitTemporalLog.Value("SourceRelativeLocation", SourceRelativeLocation);
		OrbitTemporalLog.Value("TargetRelativeLocation", TargetRelativeLocation);

		OrbitTemporalLog.Value("RelativeToPivotLocation", RelativeToPivotLocation);
#endif

		// We need to blend in the entire camera before we finish
		return BlendFraction < 1 - KINDA_SMALL_NUMBER;
	}

	/**
	 * Some cases currently can't be handled by a snap...
	 * If any of these cases occur, we could still probably find a nice pivot.
	 * But the blends are completely state-less, so whenever any of these conditions change,
	 * we could get a new pivot point, which makes this extremely un-smooth.
	 * This might be a no-go for the camera system, but this blend would require setting the pivot point once,
	 * and not changing it. For example, if the initial target view were supplied in AdvancedInfo.
	 */
	private bool CanBlend(
		FHazeViewBlendInfo SourceView,
		FHazeViewBlendInfo TargetView,
	) const
	{
		if(SourceView.Location.Equals(TargetView.Location))
			return false;

		if(SourceView.Rotation.ForwardVector.Parallel(TargetView.Rotation.ForwardVector))
			return false;

		// if(SourceView.Rotation.ForwardVector.DotProduct(TargetView.Rotation.ForwardVector) < 0)
		// 	return false;

		return true;
	}

	private FVector GetPivotPoint(
		FHazeViewBlendInfo SourceView,
		FHazeViewBlendInfo TargetView,
		FHazeCameraViewPointBlendAdvanced AdvancedInfo
	) const
	{
		switch(PivotPointType)
		{
			case ECameraOrbitBlendPivotPointType::CameraUser:
			{
				return AdvancedInfo.CurrentUserTransform.Location;
			}

			case ECameraOrbitBlendPivotPointType::SourceTargetDirectionIntersection:
			{
				return GetSourceTargetDirectionIntersectionPivotPoint(SourceView, TargetView, AdvancedInfo);
			}
		}
	}

	private FVector GetSourceTargetDirectionIntersectionPivotPoint(
		FHazeViewBlendInfo SourceView,
		FHazeViewBlendInfo TargetView,
		FHazeCameraViewPointBlendAdvanced AdvancedInfo
	) const
	{
		const FVector SourceLocation = SourceView.Location;
		const FVector SourceDirection = SourceView.Rotation.ForwardVector;

		const FVector TargetLocation = TargetView.Location;
		const FVector TargetDirection = TargetView.Rotation.ForwardVector;

		const FVector UserLocation = AdvancedInfo.SourceUserTransform.Location;
		const FVector VerticalAxis = AdvancedInfo.SourceUserTransform.Rotation.UpVector;

		if(SourceDirection.Parallel(TargetDirection))
		{
			// CURRENTLY UNUSED: SEE COMMENT ON CanBlend()
			// Source and target directions are parallel
			// This means that they will never intersect, thus we cannot make an automatic pivot, but
			// this should be fine as we won't rotate anyways, unless we are facing completely backwards,
			// in which case this is not fine at all tbh
			return Math::ClosestPointOnInfiniteLine(SourceLocation, SourceLocation + SourceDirection, UserLocation);
		}

		if(SourceDirection.DotProduct(TargetDirection) > 0)
		{
			// If the directions are facing each other, find where the forward directions intersect
			const FVector SourceRight = VerticalAxis.CrossProduct(SourceDirection);
			const FPlane SourcePlane = FPlane(
				SourceLocation,
				SourceRight
			);

#if !RELEASE
			auto TemporalLog = GetCameraTemporalLog();
			TemporalLog.Plane(f"{CameraDebug::CategoryBlend};PivotPlane", SourceLocation, SourcePlane.Normal);
#endif

			return SourcePlane.RayPlaneIntersection(TargetLocation, TargetDirection);
		}
		else
		{
			// If the directions are opposing each other, just use the user location on the target direction as the pivot point
			return Math::ClosestPointOnInfiniteLine(TargetLocation, TargetLocation + TargetDirection, UserLocation);
		}
	}

	private FTransform ConvertViewToTransform(FHazeViewBlendInfo View) const
	{
		return FTransform(View.Rotation, View.Location);
	}
}