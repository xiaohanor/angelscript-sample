class UWingSuitPlayerCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraControl);

	default CapabilityTags.Add(CapabilityTags::Input);

    default DebugCategory = CameraTags::Camera;
	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 1;

	AWingSuit WingSuit;
	UWingSuitPlayerComponent WingSuitComp;
	UPlayerMovementComponent MoveComp;
	UWingSuitSettings Settings;
	UCameraSettings CameraSettings;
	UCameraUserComponent UserComp;

	FVector PoiDefaultOffset = FVector::ZeroVector;
	FHazeAcceleratedVector PoiOffset;
	FVector OriginalOffset;

	const float DefaultPoiBlendInTime = 3.0;
	const float PoiBlendInTimeFromWaterski = 4.0;

	float PoiBlendInTime;
	FHazeAcceleratedFloat AcceleratedFOV;
	FHazeAcceleratedFloat AcceleratedIdealDistance;
	FHazeAcceleratedVector AcceleratedPivotOffset;
	bool bInitializedAcceleratedValues = false;
	bool bSnappedPoi = false;
	uint FrameOfStartPoi;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UCameraUserComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		WingSuit = WingSuitComp.WingSuit;
		Settings = UWingSuitSettings::GetSettings(Player);
		PoiDefaultOffset = WingSuit.PointOfInterestLocation.RelativeLocation;
		CameraSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WingSuitComp.bWingsuitActive && !WingSuitComp.bActivateWingsuitCameraFromCutscene)
			return false;

		if(Player.IsPlayerDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WingSuitComp.bWingsuitActive && !WingSuitComp.bActivateWingsuitCameraFromCutscene)
			return true;

		if(Player.IsPlayerDead())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bSnappedPoi = false;
		PoiBlendInTime = WingSuitComp.bTransitioningFromWaterski ? PoiBlendInTimeFromWaterski : DefaultPoiBlendInTime;
		if(WingSuitComp.bActivateWingsuitCameraFromCutscene || WingSuitComp.bShouldSnapCameraPostRespawn)
		{
			PoiBlendInTime = 0.0;
			WingSuitComp.SyncedHorizontalMovementOrientation.Value = Player.ActorForwardVector.ToOrientationRotator();
			WingSuitComp.SyncedHorizontalMovementOrientation.SnapRemote();
			WingSuitComp.CurrentPitchOffset = Settings.TargetPitchOffset;
			WingSuitComp.bShouldSnapCameraPostRespawn = false;
			bSnappedPoi = true;
		}

		FTransform WingSuitHorizontalTransform = FTransform(WingSuitComp.SyncedHorizontalMovementOrientation.Value, Player.ActorLocation);
		
		WingSuit.PointOfInterestCurrentOffset = PoiDefaultOffset;
		OriginalOffset = WingSuit.PointOfInterestCurrentOffset;
		OriginalOffset.Y = 0.0;
		PoiOffset.SnapTo(OriginalOffset, FVector::ZeroVector);
		FVector WorldInitialPoiLocation = WingSuitHorizontalTransform.TransformPosition(WingSuit.PointOfInterestCurrentOffset);
		WingSuit.PointOfInterestLocation.WorldLocation = WorldInitialPoiLocation;

		WingSuit.SyncedPOIWorldLocation.Value = WorldInitialPoiLocation;
		WingSuit.SyncedPOIWorldLocation.SnapRemote();

		StartPoi(PoiBlendInTime);

		CameraSettings.CameraOffset.Apply(FVector::ZeroVector, this, Priority = EHazeCameraPriority::High);
		CameraSettings.CameraOffsetOwnerSpace.Apply(FVector::ZeroVector, this, Priority = EHazeCameraPriority::High);
		CameraSettings.PivotLagAccelerationDuration.Apply(FVector(0.1, 0, 0), this, Priority = EHazeCameraPriority::High);
		CameraSettings.PivotLagMax.Apply(FVector(0, 0, 0), this, Priority = EHazeCameraPriority::High);
		bInitializedAcceleratedValues = false;

		Player.BlockCapabilities(CapabilityTags::CenterView, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StopPoi();
		Player.ClearCameraSettingsByInstigator(this, 3.0);
		WingSuit.PointOfInterestLocation.SetRelativeLocationAndRotation(PoiDefaultOffset, FRotator::ZeroRotator);
		UserComp.ClearYawAxis(this);

		Player.UnblockCapabilities(CapabilityTags::CenterView, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bSnappedPoi && FrameOfStartPoi + 1 == Time::FrameNumber)
		{
			StopPoi();
			StartPoi(DefaultPoiBlendInTime);
			bSnappedPoi = false;
		}

		float Speed = MoveComp.Velocity.Size();
		if(WingSuitComp.bActivateWingsuitCameraFromCutscene)
			Speed = Player.GetRawLastFrameTranslationVelocity().Size();
	
		if(HasControl() && WingSuitComp.bActivateWingsuitCameraFromCutscene)
		{
			FVector HorizontalMovementDirection = Player.GetRawLastFrameTranslationVelocity().VectorPlaneProject(FVector::UpVector);
			if(HorizontalMovementDirection.IsNearlyZero())
				HorizontalMovementDirection = Player.ActorForwardVector;
			WingSuitComp.SyncedHorizontalMovementOrientation.Value = HorizontalMovementDirection.ToOrientationRotator();
		}

		float FOV = Settings.CameraSpeedFov.GetMappedRangeValueClamped(Speed, Settings.CameraSpeedRange);
		float IdealDistance = Settings.CameraHorizontalOffset.GetMappedRangeValueClamped(Speed, Settings.CameraSpeedRange);
		FVector PivotOffset = FVector(0, 0, Settings.CameraVerticalOffset);

		if(!bInitializedAcceleratedValues)
		{
			AcceleratedFOV.SnapTo(FOV);
			AcceleratedIdealDistance.SnapTo(IdealDistance);
			AcceleratedPivotOffset.SnapTo(PivotOffset);
			bInitializedAcceleratedValues = true;
		}
		else
		{
			const float AccelerationDuration = 1.5;
			FOV = AcceleratedFOV.AccelerateTo(FOV, AccelerationDuration, DeltaTime);
			IdealDistance = AcceleratedIdealDistance.AccelerateTo(IdealDistance, AccelerationDuration, DeltaTime);
			PivotOffset = AcceleratedPivotOffset.AccelerateTo(PivotOffset, AccelerationDuration, DeltaTime);
		}

		CameraSettings.FOV.ApplyAsAdditive(FOV, this);
		CameraSettings.IdealDistance.Apply(IdealDistance, this, Priority = EHazeCameraPriority::High);
		CameraSettings.PivotOffset.Apply(PivotOffset, this, Priority = EHazeCameraPriority::High);

		const FVector AxisToRotateAround = WingSuitComp.SyncedHorizontalMovementOrientation.Value.RightVector;
		FVector CurrentUpVector = FVector::UpVector;
		CurrentUpVector = CurrentUpVector.RotateAngleAxis(WingSuitComp.CurrentPitchOffset, AxisToRotateAround);
		UserComp.SetYawAxis(CurrentUpVector, this);

		if(HasControl())
		{
			// Apply a camera pitch offset depending on how much we pitch down the wingsuit
			float CurrentPitch = WingSuitComp.InterpedRotation.Pitch;
			if(CurrentPitch < KINDA_SMALL_NUMBER)
			{
				float PitchAlpha = (Math::Abs(CurrentPitch) / Settings.PitchDownMaxAngle);

				FRotator PoiPitchOffset = FRotator::ZeroRotator;
				PoiPitchOffset.Pitch = -Settings.PitchDownCameraPitchAmount.GetFloatValue(PitchAlpha);
				FVector NewOffset = PoiPitchOffset.RotateVector(PoiDefaultOffset);

				NewOffset = PoiOffset.AccelerateTo(NewOffset, 0.2, DeltaTime);
				NewOffset = FRotator(-WingSuitComp.CurrentPitchOffset, 0.0, 0.0).RotateVector(NewOffset);
				if(PoiBlendInTime > 0.0)
					WingSuit.PointOfInterestCurrentOffset = Math::EaseInOut(OriginalOffset, NewOffset, Math::Saturate(ActiveDuration / PoiBlendInTime), 2.0);
				else
					WingSuit.PointOfInterestCurrentOffset = NewOffset;
			}
			else
			{
				FVector NewOffset = PoiOffset.AccelerateTo(PoiDefaultOffset, 1, DeltaTime);
				NewOffset = FRotator(-WingSuitComp.CurrentPitchOffset, 0.0, 0.0).RotateVector(NewOffset);
				if(PoiBlendInTime > 0.0)
					WingSuit.PointOfInterestCurrentOffset = Math::EaseInOut(OriginalOffset, NewOffset, Math::Saturate(ActiveDuration / PoiBlendInTime), 2.0);
				else
					WingSuit.PointOfInterestCurrentOffset = NewOffset;
			}

			FTransform WingSuitHorizontalTransform = FTransform(WingSuitComp.SyncedHorizontalMovementOrientation.Value, Player.ActorLocation);
			WingSuit.SyncedPOIWorldLocation.Value = WingSuitHorizontalTransform.TransformPosition(WingSuit.PointOfInterestCurrentOffset);
		}
		
		WingSuit.PointOfInterestLocation.WorldLocation = WingSuit.SyncedPOIWorldLocation.Value;
		// Debug::DrawDebugPoint(WingSuit.PointOfInterestLocation.WorldLocation, 15.f, FLinearColor::Red);
		// Debug::DrawDebugArrow(Player.ActorLocation, Player.ActorLocation + WingSuitComp.SyncedHorizontalMovementOrientation.Value.ForwardVector * 1000.0, 20, FLinearColor::Red, 5.0);

#if !RELEASE
		TEMPORAL_LOG(this)
			.Point("WingSuit Location", WingSuit.ActorLocation, 15.f)
			.Point("WingSuit POI Location", WingSuit.PointOfInterestLocation.WorldLocation, 15.f)
		;
#endif
	}

	void StartPoi(float BlendTime)
	{
		auto POI = Player.CreatePointOfInterestClamped();
		POI.Clamps = FHazeCameraClampSettings(25, 15);
		POI.FocusTarget.SetFocusToComponent(WingSuit.PointOfInterestLocation);
		POI.Apply(this, BlendTime);
		FrameOfStartPoi = Time::FrameNumber;
	}

	void StopPoi()
	{
		Player.ClearPointOfInterestByInstigator(this);
	}
};