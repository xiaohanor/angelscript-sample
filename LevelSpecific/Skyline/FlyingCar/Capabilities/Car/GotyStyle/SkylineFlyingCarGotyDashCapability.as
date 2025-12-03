
enum EFlyingCarDashManeuver
{
	Horizontal,
	Vertical,
}

class USkylineFlyingCarGotyDashCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(FlyingCarTags::FlyingCarMovement);
	default CapabilityTags.Add(FlyingCarTags::FlyingCarDash);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 80;

	ASkylineFlyingCar Car;
	USkylineFlyingCarGotySettings Settings;

	UHazeMovementComponent MovementComponent;

	FVector2D InitialInput;
	EFlyingCarDashManeuver ManeuverType;

	UHazeCrumbSyncedRotatorComponent CrumbedMeshRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Car = Cast<ASkylineFlyingCar>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);

		Settings = USkylineFlyingCarGotySettings::GetSettings(Owner);

		CrumbedMeshRotation = UHazeCrumbSyncedRotatorComponent::GetOrCreate(Car, n"DashMeshRotation");
		CrumbedMeshRotation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::MovementDash))
			return false;

	    if (Car.ActiveHighway == nullptr)
			return false;

		if (Car.bJustSplineHopped || Car.IsSplineHopping())
			return false;

		if (!Car.CanManeuver())
			return false;

        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration >= Settings.DashDuration)
			return true;

        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Car.bIsSplineDashing = true;

		// auto CameraSettings = UCameraSettings::GetSettings(Car.CurrentPilot);

		// const float BlendTime = 0.2;
		// CameraSettings.PivotOffset.Apply(FVector::UpVector * 20, BlendTime, this, FHazeCameraSettingsPriority(EHazeCameraPriority::High));
		// CameraSettings.WorldPivotOffset.Apply(FVector::UpVector * 200, BlendTime, this, FHazeCameraSettingsPriority(EHazeCameraPriority::High));
		// CameraSettings.CameraOffset.Apply(FVector::ZeroVector, BlendTime, this, FHazeCameraSettingsPriority(EHazeCameraPriority::High));
		// CameraSettings.CameraOffsetOwnerSpace.Apply(FVector::ZeroVector, BlendTime, this, FHazeCameraSettingsPriority(EHazeCameraPriority::High));
		// CameraSettings.PivotLagAccelerationDuration.Apply(FVector(0.5, 0.5, 1000.0), 0.2, this, FHazeCameraSettingsPriority(EHazeCameraPriority::High));
		// CameraSettings.PivotLagAccelerationDuration.Apply(FVector(1200), 0.2, this, FHazeCameraSettingsPriority(EHazeCameraPriority::High));


		// Determine roll direction
		if (Math::Abs(Car.YawInput) > Math::Abs(Car.PitchInput))
		{
			ManeuverType = EFlyingCarDashManeuver::Horizontal;
		}
		else
		{
			ManeuverType = EFlyingCarDashManeuver::Vertical;
			// CameraSettings.IdealDistance.Apply(800, Settings.DashDuration * 0.5, this, EHazeCameraPriority::High);
		}

		InitialInput = FVector2D(Car.YawInput, Car.PitchInput);

		// CameraSettings.PivotOffset.Apply(FVector::UpVector * 50, Settings.DashDuration * 0.5, this, EHazeCameraPriority::High);

		USkylineFlyingCarEventHandler::Trigger_OnDash(Car);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Car.bIsSplineDashing = false;

		Car.CurrentPilot.ClearCameraSettingsByInstigator(this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			FSkylineFlyingCarSplineParams SplineParams;
			Car.GetSplineDataAtPosition(Car.ActorLocation, SplineParams);

			// Calculate Dash impulse and add it
			float DashExp = ManeuverType == EFlyingCarDashManeuver::Vertical ? 3.0 : 1.3;
			DashExp = 0.5; // Eman TODO: Trying out values

			float DashAlpha = Math::Pow(Math::Saturate(ActiveDuration / Settings.DashDuration), DashExp) * 1.4;
			float Magnitude = Settings.DashImpulse * Math::Saturate(Math::Sin(DashAlpha * PI)) * GetDashImpulseMultiplier(SplineParams);

			FVector DashDirection = (SplineParams.SplinePosition.WorldRightVector * InitialInput.X + SplineParams.SplinePosition.WorldUpVector * InitialInput.Y).GetSafeNormal();
			FVector Impulse = DashDirection * Magnitude;

			MovementComponent.AddPendingImpulse(Impulse);

			CrumbedMeshRotation.Value = GetCarMeshRotation(DashExp, DashDirection, DeltaTime);
		}

		Car.MeshRoot.SetWorldRotation(CrumbedMeshRotation.Value);
	}

	FRotator GetCarMeshRotation(float DashExp, FVector DashDirection, float DeltaTime)
	{
		switch (ManeuverType)
		{
			case EFlyingCarDashManeuver::Horizontal:
			{
				// Rotate mesh
				// float RotationAlpha = Math::Pow(Math::Saturate(ActiveDuration / Settings.DashDuration), DashExp);
				// FVector UpVector = FVector::UpVector.RotateAngleAxis(360 * RotationAlpha * -Math::Sign(DashDirection.DotProduct(Car.ActorRightVector)), Car.MeshRoot.ForwardVector);
				// FQuat Rotation = FQuat::MakeFromXZ(Car.MeshRoot.ForwardVector, UpVector);

				float CurvedFraction = Math::Pow(Math::Saturate(ActiveDuration / Settings.DashDuration), 0.4) * 1.5;
				float RotationAlpha = 1.5 - Math::Abs(CurvedFraction * 2 - 1.5);
				FVector UpVector = FVector::UpVector.RotateAngleAxis(20 * RotationAlpha * -Math::Sign(DashDirection.DotProduct(Car.ActorRightVector)), Car.MeshRoot.ForwardVector);
				FRotator Rotation = FRotator::MakeFromXZ(Car.MeshRoot.ForwardVector, UpVector);
				Rotation = Math::RInterpTo(Car.MeshRoot.WorldRotation, Rotation, DeltaTime, 5.0);

				return Rotation;
			}

			case EFlyingCarDashManeuver::Vertical:
			{
				// float SpeedMultiplier = 1.3;
				// float RotationAlpha = Math::Saturate((ActiveDuration * SpeedMultiplier) / Settings.DashDuration);

				// // Use same rotation regardless of direction (?)
				// float Angle = -1.0 * PI * Math::Pow(RotationAlpha, 2.5) * 2;
				// float LerpTime = 10 * SpeedMultiplier;

				// FQuat TargetRotation = FQuat(Car.MeshRoot.RightVector, Angle) * Car.RollRoot.WorldRotation.Quaternion();
				// FQuat Rotation = Math::QInterpConstantTo(Car.MeshRoot.WorldRotation.Quaternion(), TargetRotation, DeltaTime, LerpTime);
				// Car.MeshRoot.SetWorldRotation(Rotation);

				// // Grow and shrink offset ship rotates around
				// float OffsetAlpha = 1.0 - Math::Abs(RotationAlpha * 2.0 - 1.0);
				// float Offset = Math::Lerp(0, -200, OffsetAlpha);

				// Car.StaticMesh.SetRelativeLocation(FVector::UpVector * Offset);

				float RotationMultiplier = 1.0 - Math::Saturate(ActiveDuration / Settings.DashDuration);
				FQuat TargetRotation = Car.ActorQuat * FQuat(Car.MeshRoot.RightVector * -Math::Sign(DashDirection.DotProduct(FVector::UpVector)), Math::DegreesToRadians(20 * RotationMultiplier));
				FQuat Rotation = Math::QInterpTo(Car.MeshRoot.ComponentQuat, TargetRotation, DeltaTime, 5);

				return Rotation.Rotator();
			}
		}
	}

	// Add more impulse if we are Dashing away from spline
	float GetDashImpulseMultiplier(const FSkylineFlyingCarSplineParams& SplineParams) const
	{
		// if (Car.IsSplineHopping())
		// 	return 5.0;

		return 1.0;

		// if (!Car.ActiveHighway.bCanDashAwayFromHighway)
		// 	return 1.0;


		// float VerticalMultiplier = 2.0;
		// float SteeringMultiplier = Math::Saturate(2.0 - SplineParams.DirToSpline.DotProduct(Car.ActorVelocity.GetSafeNormal()));
		// float SplineDistanceMultiplier = 1.0 + Math::Pow((SplineParams.SplineHorizontalDistanceAlphaUnclamped + SplineParams.SplineVerticalDistanceAlphaUnclamped) * 0.5, 2);

		// float Multiplier = SteeringMultiplier + SplineDistanceMultiplier * VerticalMultiplier;
		// return Multiplier;
	}
}