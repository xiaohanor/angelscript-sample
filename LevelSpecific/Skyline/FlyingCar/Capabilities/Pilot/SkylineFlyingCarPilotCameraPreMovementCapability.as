class USkylineFlyingCarPilotCameraPreMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

    default DebugCategory = CameraTags::Camera;
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 2;

	USkylineFlyingCarPilotComponent PilotComponent;
	UCameraUserComponent CameraUser;
	UHazeOffsetComponent CameraRoot;
	UHazeCameraSettingsDataAsset CurrentCameraSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PilotComponent = USkylineFlyingCarPilotComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PilotComponent.Car == nullptr)
	        return false;

        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PilotComponent.Car == nullptr)
	        return true;

        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{		
		CameraUser.SnapCamera(PilotComponent.Car.GetActorForwardVector());
		
		UHazeCameraSettingsDataAsset TargetCameraSettings;
		float CameraSettingsActivationBlend;
		PilotComponent.GetFlyingCarCameraSettings(TargetCameraSettings, CameraSettingsActivationBlend);

		if(PilotComponent.Car.IsFreeFlying())
			PilotComponent.FreeFlyPercentage = 1.0;
		else
			PilotComponent.FreeFlyPercentage = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearPointOfInterestByInstigator(this);
		Player.ClearSettingsByInstigator(this);

		#if EDITOR
		if (PilotComponent.Car != nullptr)
			PilotComponent.Car.DebugCameraSettingsText = "";
		#endif
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (PilotComponent.Car.IsCarExploding())
			return;

		if (PilotComponent.Car.IsInSplineRamp() || PilotComponent.Car.IsJumpingFromSplineRamp())
		{
			PilotComponent.FreeFlyPercentage = Math::FInterpTo(PilotComponent.FreeFlyPercentage, 0.0, DeltaTime, PilotComponent.BlendInSpeed);
			PilotComponent.TunnelPercentage = Math::FInterpTo(PilotComponent.TunnelPercentage, 0.0, DeltaTime, PilotComponent.BlendInSpeed);
			PilotComponent.RampPercentage = Math::FInterpTo(PilotComponent.RampPercentage, 1.0, DeltaTime, PilotComponent.BlendInSpeed);
		}
		else if(PilotComponent.Car.IsFreeFlying() || PilotComponent.Car.IsAnyCapabilityActive(FlyingCarTags::FlyingCarGroundMovement))
		{
			PilotComponent.FreeFlyPercentage = Math::FInterpTo(PilotComponent.FreeFlyPercentage, 1.0, DeltaTime, PilotComponent.BlendInSpeed);
			PilotComponent.TunnelPercentage = Math::FInterpTo(PilotComponent.TunnelPercentage, 0.0, DeltaTime, PilotComponent.BlendInSpeed);
			PilotComponent.RampPercentage = Math::FInterpTo(PilotComponent.RampPercentage, 0.0, DeltaTime, PilotComponent.BlendInSpeed);
		}
		else if (PilotComponent.IsInTunnel())
		{
			PilotComponent.FreeFlyPercentage = Math::FInterpTo(PilotComponent.FreeFlyPercentage, 0.0, DeltaTime, PilotComponent.BlendInSpeed);
			PilotComponent.TunnelPercentage = Math::FInterpTo(PilotComponent.TunnelPercentage, 1.0, DeltaTime, PilotComponent.BlendInSpeed);
			PilotComponent.RampPercentage = Math::FInterpTo(PilotComponent.RampPercentage, 0.0, DeltaTime, PilotComponent.BlendInSpeed);
		}
		else
		{
			PilotComponent.FreeFlyPercentage = Math::FInterpConstantTo(PilotComponent.FreeFlyPercentage, 0.0, DeltaTime, 1.0 / PilotComponent.BlendInSpeed);
			PilotComponent.RampPercentage = Math::FInterpConstantTo(PilotComponent.RampPercentage, 0.0, DeltaTime, 1.0 / PilotComponent.BlendInSpeed);
			PilotComponent.TunnelPercentage = Math::FInterpTo(PilotComponent.TunnelPercentage, 0.0, DeltaTime, 1.0 / PilotComponent.BlendInSpeed);
		}

		PilotComponent.UpdateSettingsAlphas(DeltaTime);

		UHazeCameraSettingsDataAsset TargetCameraSettings;
		float CameraSettingsActivationBlend = 2;
		PilotComponent.GetFlyingCarCameraSettings(TargetCameraSettings, CameraSettingsActivationBlend);
		if(CurrentCameraSettings != TargetCameraSettings)
		{
			if(TargetCameraSettings != nullptr)
			{
				if (CurrentCameraSettings != nullptr)
					Player.ClearCameraSettingsByInstigator(this, CameraSettingsActivationBlend);

				CurrentCameraSettings = TargetCameraSettings;
				Player.ApplyCameraSettings(TargetCameraSettings, CameraSettingsActivationBlend, this);
			}
		}

		FVector CarLocation = PilotComponent.Car.ActorLocation;
		FRotator CurrentDesiredRotation = CameraUser.DesiredRotation;
		FRotator CarLookAtRotation = PilotComponent.Car.GetActorForwardVector().ToOrientationRotator();

		if(PilotComponent.Car.ActiveHighway != nullptr && PilotComponent.LookAheadAlpha > 0 && PilotComponent.TargetLookAtLocationLookAheadDistance > 0)
		{
			FSplinePosition SplinePosition = PilotComponent.Car.ActiveHighway.HighwaySpline.GetClosestSplinePositionToWorldLocation(CarLocation);
			const FVector CurrentSplinePosition = SplinePosition.WorldLocation; 
			SplinePosition.Move(PilotComponent.TargetLookAtLocationLookAheadDistance);

			FRotator TargetRotation = (SplinePosition.WorldLocation - CurrentSplinePosition).ToOrientationRotator();
			TargetRotation = Math::LerpShortestPath(CarLookAtRotation, TargetRotation, Math::Clamp(PilotComponent.LookAheadAlpha, 0.0, 1.0));

			// Accelerate slower if we just switched highway spline
			float Alpha = Math::Square(Math::Saturate(PilotComponent.Car.TimeSinceLastHighwaySwitch / PilotComponent.HighwayTransitionDuration));
			float InterpSpeed = Math::Lerp(1.0, PilotComponent.ForceCameraLookDirectionSpeed, Alpha);

			CarLookAtRotation = Math::RInterpConstantShortestPathTo(CarLookAtRotation, TargetRotation, DeltaTime, InterpSpeed);

#if EDITOR
			if (PilotComponent.Car.DebugDrawer.IsVisible())
			{
				Debug::DrawDebugSphere(SplinePosition.WorldLocation, 100, 20, FLinearColor::Green, 5, 0, false);

				FVector VerticalOffset = SplinePosition.WorldUpVector * 5000;
				Debug::DrawDebugLine(SplinePosition.WorldLocation - VerticalOffset, SplinePosition.WorldLocation + VerticalOffset, FLinearColor::Green, 50, 0, false);
			}
#endif
		}

		CarLookAtRotation = (CarLookAtRotation.Quaternion() * FRotator(PilotComponent.TargetPitchOffset, 0.0, 0.0).Quaternion()).Rotator();

		// float Alpha = Math::Square(Math::Saturate(PilotComponent.Car.TimeSinceLastHighwaySwitch / PilotComponent.HighwayTransitionDuration));
		// float InterpSpeed = Math::Lerp(4.0, PilotComponent.ForceCameraLookDirectionSpeed, Alpha);

		CurrentDesiredRotation = Math::RInterpTo(CurrentDesiredRotation, CarLookAtRotation, DeltaTime, PilotComponent.ForceCameraLookDirectionSpeed);
		CameraUser.SetDesiredRotation(CurrentDesiredRotation, this);

		#if EDITOR
		FString& Debug = PilotComponent.Car.DebugCameraSettingsText;
		Debug = "";
		Debug += "HorizontalFollowCarPercentage: " + PilotComponent.HorizontalFollowCarPercentage + "\n";
		Debug += "VerticalFollowCarPercentage: " + PilotComponent.VerticalFollowCarPercentage + "\n";
		Debug += "LookAheadAlpha: " + PilotComponent.LookAheadAlpha + "\n";
		Debug += "TargetLookAtLocationLookAheadDistance: " + PilotComponent.TargetLookAtLocationLookAheadDistance + "\n";
		Debug += "TargetPitchOffset: " + PilotComponent.TargetPitchOffset + "\n";
		Debug += "ForceCameraLookDirectionSpeed: " + PilotComponent.ForceCameraLookDirectionSpeed + "\n";
		Debug += "FreeFlyPercentage: " + PilotComponent.FreeFlyPercentage + "\n";
		Debug += "TunnelPercentage: " + PilotComponent.TunnelPercentage + "\n";
		Debug += "RampPercentage: " + PilotComponent.RampPercentage + "\n";
		#endif
	}
}