class UHackableSniperTurretCameraCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDroneHijackCapability);
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 120;

	AHackableSniperTurret SniperTurret;
	AHazePlayerCharacter Player;
	UCameraUserComponent CameraUserComp;
	UCameraSettings CameraSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SniperTurret = Cast<AHackableSniperTurret>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SniperTurret.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SniperTurret.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player = SniperTurret.HijackTargetableComp.GetHijackPlayer();
		CameraUserComp = UCameraUserComponent::Get(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);
		CameraSettings.SensitivityFactor.Apply(1, this, 0, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CameraSettings.SensitivityFactor.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FRotator TurnRate = GetCameraTurnRate();
			const FVector2D CameraInput = Player.GetCameraInput();

			const float CameraSensitivity = Math::Lerp(
				SniperTurret.CameraSensitivity,
				SniperTurret.CameraSensitivity * SniperTurret.ZoomedSensitivityMultiplier,
				SniperTurret.ZoomAlpha.Value
			);

			TurnRate *= CameraSensitivity;

			FRotator DeltaRotation = CalculateAndUpdateInputDeltaRotation(CameraInput, TurnRate, DeltaTime);

			SniperTurret.ControlAddToSniperRotation(DeltaRotation.Yaw, DeltaRotation.Pitch);
		
			CameraUserComp.SetInputRotation(SniperTurret.SyncedAimRotation.Value, this);
		}

		SniperTurret.ApplySniperRotation();

		const FHitResult Hit = SniperTurret.Trace();
		if(Hit.bBlockingHit)
		{
			SniperTurret.DistanceToTarget = Hit.Distance;
		}
		else
		{
			SniperTurret.DistanceToTarget = -1;
		}

		if(SniperTurret.bDrawLaserPointer)
			DrawLaserPointer(Hit);


		// SniperTurret.PostProcessSettings.DepthOfFieldSensorWidth = 1000;
		// SniperTurret.PostProcessSettings.DepthOfFieldSqueezeFactor = 2;

		// SniperTurret.PostProcessSettings.bOverride_DepthOfFieldFocalRegion = true;
		// SniperTurret.PostProcessSettings.DepthOfFieldFocalRegion = 1000;
		// SniperTurret.PostProcessSettings.DepthOfFieldFocalDistance = Hit.Distance;

		// SniperTurret.PostProcessSettings.DepthOfFieldDepthBlurRadius = 1;

		// Player.AddCustomPostProcessSettings(SniperTurret.PostProcessSettings,10,this);

		// Player.CurrentlyUsedCamera.PostProcessSettings = SniperTurret.PostProcessSettings;
		// Print(""+Player.CurrentlyUsedCamera.PostProcessSettings.DepthOfFieldFocalDistance);

	}

	void DrawLaserPointer(FHitResult Hit)
	{
		check(SniperTurret.bDrawLaserPointer);

		FSniperTurretOnDrawLaserPointer Params;
		Params.Hit = Hit;
		Params.MuzzleWorldTransform = SniperTurret.MuzzleComp.WorldTransform;
		UHackableSniperTurretEventHandler::Trigger_OnDrawLaserPointer(SniperTurret, Params);
	}

	FRotator GetCameraTurnRate() const
	{		
		FRotator TurnRate = CameraUserComp.DefaultAimCameraTurnRate;	

		TurnRate.Yaw *= Player.GetSensitivity(EHazeSensitivityType::Yaw) * CameraSettings.SensitivityFactorYaw.Value;
		TurnRate.Pitch *= Player.GetSensitivity(EHazeSensitivityType::Pitch) * CameraSettings.SensitivityFactorPitch.Value;

		if (!Player.IsUsingGamepad())
		{
			TurnRate.Yaw *= Player.GetSensitivity(EHazeSensitivityType::MouseYaw);
			TurnRate.Pitch *= Player.GetSensitivity(EHazeSensitivityType::MousePitch);
		}

		return TurnRate;
	}

	FRotator CalculateAndUpdateInputDeltaRotation(FVector2D AxisInput, FRotator TurnRate, float DeltaTime)
	{
		FRotator DeltaRotation = FRotator::ZeroRotator;
		if (Player.IsUsingGamepad())
		{
			DeltaRotation.Yaw = AxisInput.X * (TurnRate.Yaw * DeltaTime);
			DeltaRotation.Pitch = AxisInput.Y * (TurnRate.Pitch * DeltaTime);
		}
		else
		{
			// We cant use delta time on mouse input. But without this, the input becomes to big.
			const float MouseMultiplier = 0.01;
			
			DeltaRotation.Yaw = AxisInput.X * TurnRate.Yaw * MouseMultiplier;
			DeltaRotation.Pitch = AxisInput.Y * TurnRate.Pitch * MouseMultiplier;
		}

		return DeltaRotation;
	}
};