class USanctuaryLightBirdShieldFocusCameraCapability : UHazePlayerCapability
{
//	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"LightBirdShield");

	default TickGroup = EHazeTickGroup::Gameplay;

	USanctuaryLightBirdShieldUserComponent UserComp;
	USceneComponent FocusTargetComp;
	UHazeSplineComponent Spline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USanctuaryLightBirdShieldUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bUseFocusCamera.Get())
			return false;

		if (!HasFocusSpline())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bUseFocusCamera.Get())
			return true;

		if (!HasFocusSpline())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (Player.IsMio())
			for (auto CameraSettings : UserComp.Settings.MioCameraSettings)
				Player.ApplyCameraSettings(CameraSettings, 1.0, this, EHazeCameraPriority::High);

		if (Player.IsZoe())
			for (auto CameraSettings : UserComp.Settings.ZoeCameraSettings)
				Player.ApplyCameraSettings(CameraSettings, 1.0, this, EHazeCameraPriority::High);

		auto SplineActor = TListedActors<ASanctuaryLightBirdShieldCameraFocusSpline>().Single;
		if (SplineActor != nullptr)
			Spline = UHazeSplineComponent::Get(SplineActor);

		FocusTargetComp = USceneComponent::Create(Player);
		FocusTargetComp.DetachFromParent();
		FHazePointOfInterestFocusTargetInfo FocusTarget;
		FocusTarget.SetFocusToComponent(FocusTargetComp);

		auto SplinePosition = Spline.GetClosestSplinePositionToWorldLocation(Player.OtherPlayer.ActorLocation);
		FocusTargetComp.WorldLocation = SplinePosition.WorldLocation;

		FApplyClampPointOfInterestSettings ClampedPOISettings;
		ClampedPOISettings.InputCounterForce = 1.5;
		ClampedPOISettings.bUseFocusTargetComponentForClamps = true;
		ClampedPOISettings.bBlockFindAtOtherPlayer = true;
		Player.ApplyClampedPointOfInterest(this, FocusTarget, ClampedPOISettings, FHazeCameraClampSettings(30.0, 30.0, 60.0, 90.0), BlendInTime = 2.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearPointOfInterestByInstigator(this);
		FocusTargetComp.DestroyComponent(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto SplinePosition = Spline.GetClosestSplinePositionToWorldLocation(Player.OtherPlayer.ActorLocation);

		float Distance = Player.GetDistanceTo(Player.OtherPlayer);
		float Alpha = Math::Min(Distance / 3000.0, 1.0);
		FVector TargetFocusLocation = Math::Lerp(Player.OtherPlayer.ActorCenterLocation, SplinePosition.WorldLocation, Alpha);
		FocusTargetComp.WorldLocation = Math::Lerp(FocusTargetComp.WorldLocation, TargetFocusLocation, DeltaTime * 2.0);
//		Debug::DrawDebugPoint(SplinePosition.WorldLocation, 40.0, FLinearColor::Red, 0.0);
	}

	bool HasFocusSpline() const
	{
		return TListedActors<ASanctuaryLightBirdShieldCameraFocusSpline>().Single != nullptr;
	}
};