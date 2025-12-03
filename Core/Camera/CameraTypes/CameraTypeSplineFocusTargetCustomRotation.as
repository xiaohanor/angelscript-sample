struct FCameraFocusTargetCustomRotationData
{
	// Focus target data for location
	FCameraFocusTargetData FocusTargetData;

	// Spline info and current location-based keys
	FFocusCameraBlendSplineKeyInfo SplineKeyInfo;

	void Init(const UHazeCameraUserComponent HazeUser, AVolume InConstraintVolume = nullptr, float MatchVelocityFactor = -1)
	{
		FocusTargetData.Init(HazeUser, InConstraintVolume, MatchVelocityFactor);
	}

	FRotator GetBlendedRotation()
	{
		return Math::LerpShortestPath(SplineKeyInfo.PreviousKey.WorldRotation, SplineKeyInfo.NextKey.WorldRotation, SplineKeyInfo.Alpha);
	}
}

UCLASS(NotBlueprintable)
class UFocusTargetCustomRotationCamera : UHazeCameraComponent
{
	default CameraUpdaterType = UCameraFocusTargetCustomRotationUpdater;
	default bHasKeepInViewSettings = true;
}

#if EDITOR
class USplineFollowCustomRotationCameraVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UFocusTargetCustomRotationCamera;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		UFocusTargetCustomRotationCamera Camera = Cast<UFocusTargetCustomRotationCamera>(Component);
		if (Camera == nullptr)
			return;

		Camera.VisualizeCameraEditorPreviewLocation(this);

		ASplineFollowCustomRotationCameraActor CameraActor = Cast<ASplineFollowCustomRotationCameraActor>(Camera.Owner);
		if (CameraActor == nullptr)
			return;

		FFocusCameraBlendSplineKeyInfo KeyInfo;
		FFocusTargets FocusTargets = CameraActor.FocusTargetComponent.GetEditorPreviewTargets();
		CameraActor.FocusBlendComponent.GetBlendKeyInfoAtLocation(FocusTargets.GetWeightedCenter(), KeyInfo);

		// Visualize spline key range
		float Multiplier = Math::Lerp(0.5, 1.0, KeyInfo.Alpha);
		// if (KeyInfo.PreviousKey != nullptr)
		// 	DrawWireSphere(KeyInfo.PreviousKey.WorldLocation, 100, FLinearColor::Green * (1.5 - Multiplier), 1);

		// if (KeyInfo.NextKey != nullptr)
		// 	DrawWireSphere(KeyInfo.NextKey.WorldLocation, 100, FLinearColor::Green * Multiplier, 1);

		float Alpha = Math::FloorToFloat(KeyInfo.Alpha * 100) / 100;
		FVector PointOnSpline = CameraActor.SplineComponent.GetWorldLocationAtSplineDistance(KeyInfo.PlayerDistanceAlongSpline);
		DrawWorldString("Alpha " + Alpha, PointOnSpline, FLinearColor::LucBlue * 3, 1.5);
	}
}
#endif

UCLASS(NotBlueprintable)
class UCameraFocusTargetCustomRotationUpdater : UHazeCameraUpdater
{
	FCameraFocusTargetUserData UserData;
	FCameraFocusTargetCustomRotationData UpdaterSettings;

	// These are not part of the settings
	// because they should always be passed into the functions
	float RotationDuration = -1;
	float LocationDuration = -1;

	FFocusTargets FocusTargets;
	FFocusTargets PrimaryTargets;

	UFUNCTION(BlueprintOverride)
	void Copy(const UHazeCameraUpdater SourceBase)
	{
		auto Source = Cast<UCameraFocusTargetCustomRotationUpdater>(SourceBase);

		UserData = Source.UserData;
		UpdaterSettings = Source.UpdaterSettings;
		RotationDuration = Source.RotationDuration;
		LocationDuration = Source.LocationDuration;
		FocusTargets = Source.FocusTargets;
		PrimaryTargets = Source.PrimaryTargets;
	}

	UFUNCTION(BlueprintOverride)
	void PrepareForUser()
	{
		// Start every frame with clean settings
		// so the camera can just apply the settings it want this frame
		UpdaterSettings = FCameraFocusTargetCustomRotationData();
		FocusTargets = FFocusTargets();
		PrimaryTargets = FFocusTargets();
		RotationDuration = -1;
		LocationDuration = -1;
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraSnap(FHazeCameraTransform& CameraTransformTarget)
	{
		// Snap rotation first
		UpdateCameraRotation(CameraTransformTarget, 0.0);

		// Then snap location
		UpdateCameraLocation(CameraTransformTarget, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	protected void OnCameraUpdate(float DeltaTime, FHazeCameraTransform& CameraTransformTarget)
	{
		// Fix rotation first
		UpdateCameraRotation(CameraTransformTarget, DeltaTime);

		// Then adjust location
		UpdateCameraLocation(CameraTransformTarget, DeltaTime);
	}

	void UpdateCameraLocation(FHazeCameraTransform& CameraTransformTarget, float DeltaTime)
	{
		const FTransform TargetView = CameraTransformTarget.ViewTransform;

		if(FocusTargets.Num() > 0)
		{
			FVector NewTargetLocation = TargetView.Location;
			UpdaterSettings.FocusTargetData.GetTargetLocation(TargetView, CameraSettings, FocusTargets, PrimaryTargets, NewTargetLocation);

			// Accelerate or snap to target location
			if(LocationDuration <= 0 || DeltaTime == 0)
				UserData.PreviousViewLocation.SnapTo(NewTargetLocation);
			else
				UserData.PreviousViewLocation.AccelerateTo(NewTargetLocation, LocationDuration, DeltaTime);
		}
		else
		{
			// No active targets, slide to a stop
			float Dampening = 5.0 / Math::Max(0.1, LocationDuration);
			UserData.PreviousViewLocation.Velocity -= UserData.PreviousViewLocation.Velocity * Math::Min(1.0, Dampening * DeltaTime);
			UserData.PreviousViewLocation.Value += UserData.PreviousViewLocation.Velocity * DeltaTime;
		}

		CameraTransformTarget.ViewLocation = UserData.PreviousViewLocation.Value;
	}

	void UpdateCameraRotation(FHazeCameraTransform& CameraTransformTarget, float DeltaTime)
	{
		auto SplineKeyInfo = UpdaterSettings.SplineKeyInfo;
		if (SplineKeyInfo.IsValidRange())
		{
			FQuat FromLocalRotation = WorldToLocalQuat(UpdaterSettings.SplineKeyInfo.PreviousKey.ComponentQuat);
			FQuat ToLocalRotation = WorldToLocalQuat(UpdaterSettings.SplineKeyInfo.NextKey.ComponentQuat);

			// Interpolate rotation in local space
			FQuat TargetLocalRotation = CameraSettings.KeepInView.LookOffset.Quaternion() * FQuat::Slerp(FromLocalRotation, ToLocalRotation, SplineKeyInfo.Alpha);

			// Clamp and keep roll
			TargetLocalRotation = ClampLocalQuat(TargetLocalRotation, bWipeRoll = false);

			// Move to world and accelerate or snap
			FQuat WorldTargetRotation = LocalToWorldQuat(TargetLocalRotation);
			if (DeltaTime == 0.0)
				UserData.PreviousViewRotation.SnapTo(WorldTargetRotation);
			else
				UserData.PreviousViewRotation.AccelerateTo(WorldTargetRotation, RotationDuration, DeltaTime);
		}
		else
		{
			// Leave rotation unchanged if there are no targets
		}

		CameraTransformTarget.ViewRotation = UserData.PreviousViewRotation.Value.Rotator();
	}
}