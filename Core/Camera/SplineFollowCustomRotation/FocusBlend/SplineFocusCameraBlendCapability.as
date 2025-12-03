class USplineFocusCameraBlendCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;

	USplineFocusCameraBlendPlayerComponent SplineFocusCameraBlendPlayerComponent;
	USegmentedSplineFocusCameraBlendComponent SplineFocusCameraBlendComponent;
	UHazeSplineComponent SplineComponent;

	bool bBlendedFirstKeySettings;

	// Eman TODO: Ugh
	bool bAddedFocusTargetsNASTY;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplineFocusCameraBlendPlayerComponent = USplineFocusCameraBlendPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SplineFocusCameraBlendPlayerComponent.IsSplineFocusCameraActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SplineFocusCameraBlendPlayerComponent.IsSplineFocusCameraActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplineFocusCameraBlendComponent = SplineFocusCameraBlendPlayerComponent.SplineFocusCameraBlendComponent;
		SplineComponent = SplineFocusCameraBlendComponent.SplineComponent;

		bAddedFocusTargetsNASTY = false;

		// Get key range settings
		FFocusCameraBlendSplineKeyInfo KeyInfo;
		SplineFocusCameraBlendComponent.GetBlendKeyInfoAtLocation(Player.ActorLocation, KeyInfo);

		// Player hasn't gone past first key yet, apply these settings
		if(KeyInfo.PreviousKey == nullptr && KeyInfo.NextKey != nullptr)
		{
			ApplySettings(KeyInfo.NextKey.BlendKeySettings);

			for (auto FocusTarget : KeyInfo.NextKey.FocusTargets)
			{
				SplineFocusCameraBlendComponent.FocusCamera.FocusTargetComponent.AddFocusTarget(FocusTarget, this, SelectPlayer);
				bAddedFocusTargetsNASTY = true;
			}

			bBlendedFirstKeySettings = true;
		}
		else
		{
			bBlendedFirstKeySettings = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SplineFocusCameraBlendComponent.FocusCamera.FocusTargetComponent.RemoveAllAddFocusTargetsByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this, SplineFocusCameraBlendComponent.FocusCameraBlendSettings.BlendOut);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Don't update whilst blending-in
		if (bBlendedFirstKeySettings && ActiveDuration < SplineFocusCameraBlendComponent.FocusCameraBlendSettings.BlendIn)
			return;

		UCameraSettings CameraSettings = UCameraSettings::GetSettings(Player);

		// Get key range settings
		FFocusCameraBlendSplineKeyInfo KeyInfo;
		SplineFocusCameraBlendComponent.GetBlendKeyInfoAtLocation(Player.ActorLocation, KeyInfo);

		// Blend if player has moved beyond first key
		if (KeyInfo.PreviousKey != nullptr)
		{
			// Blend them settings
			BlendAndApplyKeySettings(KeyInfo, CameraSettings);

			// Blend focus targets
			BlendFocusTargets(KeyInfo, DeltaTime);
		}
	}

	void BlendFocusTargets(const FFocusCameraBlendSplineKeyInfo& KeyInfo, float DeltaTime)
	{
		TArray<FHazeCameraWeightedFocusTargetInfo> FromFocusTargets = KeyInfo.PreviousKey.FocusTargets;
		TArray<FHazeCameraWeightedFocusTargetInfo> ToFocusTargets = KeyInfo.NextKey.FocusTargets;

		// Eman TODO: Gross
		if (bAddedFocusTargetsNASTY)
			SplineFocusCameraBlendComponent.FocusCamera.FocusTargetComponent.RemoveAllAddFocusTargetsByInstigator(this);

		// Eman TODO: Arbitrary... expose?
		const float InterpSpeed = 20.0;

		const float Alpha = 1.0 - KeyInfo.Alpha;
		for (auto& FocusTarget : FromFocusTargets)
		{
			FocusTarget.AdvancedSettings.LocalOffset *= Alpha;
			FocusTarget.AdvancedSettings.LocalOffset *= Alpha;
			FocusTarget.AdvancedSettings.ViewOffset  *= Alpha;

			float Weight = Math::FInterpTo(FocusTarget.AdvancedSettings.Weight, FocusTarget.AdvancedSettings.Weight * (1 - KeyInfo.Alpha), DeltaTime, InterpSpeed);
			FocusTarget.AdvancedSettings.SetWeight(Weight);

			SplineFocusCameraBlendComponent.FocusCamera.FocusTargetComponent.AddFocusTarget(FocusTarget, this, SelectPlayer);
			bAddedFocusTargetsNASTY = true;
		}

		for (auto& FocusTarget : ToFocusTargets)
		{
			FocusTarget.AdvancedSettings.LocalOffset *= KeyInfo.Alpha;
			FocusTarget.AdvancedSettings.LocalOffset *= KeyInfo.Alpha;
			FocusTarget.AdvancedSettings.ViewOffset  *= KeyInfo.Alpha;

			float Weight = Math::FInterpTo(FocusTarget.AdvancedSettings.Weight, FocusTarget.AdvancedSettings.Weight * KeyInfo.Alpha, DeltaTime, InterpSpeed);
			FocusTarget.AdvancedSettings.SetWeight(Weight);

			SplineFocusCameraBlendComponent.FocusCamera.FocusTargetComponent.AddFocusTarget(FocusTarget, this, SelectPlayer);
			bAddedFocusTargetsNASTY = true;
		}
	}

	void BlendAndApplyKeySettings(FFocusCameraBlendSplineKeyInfo KeyInfo, UCameraSettings PlayerCameraSettings)
	{
		const FFocusCameraBlendSplineKeySettings& From = KeyInfo.PreviousKey.BlendKeySettings;
		const FFocusCameraBlendSplineKeySettings& To = KeyInfo.NextKey.BlendKeySettings;

		float Alpha = KeyInfo.Alpha;

		// Camera settings
		{
			if (From.CameraSettings.bUseFOV && To.CameraSettings.bUseFOV)
			{
				float FOV = Math::Lerp(From.CameraSettings.FOV, To.CameraSettings.FOV, Alpha);
				PlayerCameraSettings.FOV.Apply(FOV, this);
			}
			else if (From.CameraSettings.bUseFOV && !To.CameraSettings.bUseFOV)
			{
				PlayerCameraSettings.FOV.Apply(From.CameraSettings.FOV, this);
				PlayerCameraSettings.FOV.SetManualFraction(1.0 - Alpha, this);
			}
			else if (!From.CameraSettings.bUseFOV && To.CameraSettings.bUseFOV)
			{
				PlayerCameraSettings.FOV.Apply(To.CameraSettings.FOV, this);
				PlayerCameraSettings.FOV.SetManualFraction(Alpha, this);
			}

			if (From.CameraSettings.bUseSensitivityFactor && To.CameraSettings.bUseSensitivityFactor)
			{
				float SensitivityFactor = Math::Lerp(From.CameraSettings.SensitivityFactor, To.CameraSettings.SensitivityFactor, Alpha);
				float SensitivityFactorYaw = Math::Lerp(From.CameraSettings.SensitivityFactorYaw, To.CameraSettings.SensitivityFactorYaw, Alpha);
				float SensitivityFactorPitch = Math::Lerp(From.CameraSettings.SensitivityFactorPitch, To.CameraSettings.SensitivityFactorPitch, Alpha);

				PlayerCameraSettings.SensitivityFactor.Apply(SensitivityFactor, this);
				PlayerCameraSettings.SensitivityFactorYaw.Apply(SensitivityFactorYaw, this);
				PlayerCameraSettings.SensitivityFactorPitch.Apply(SensitivityFactorPitch, this);
			}
			else if (From.CameraSettings.bUseSensitivityFactor && !To.CameraSettings.bUseSensitivityFactor)
			{
				PlayerCameraSettings.SensitivityFactor.Apply(From.CameraSettings.SensitivityFactor, this);
				PlayerCameraSettings.SensitivityFactorYaw.Apply(From.CameraSettings.SensitivityFactorYaw, this);
				PlayerCameraSettings.SensitivityFactorPitch.Apply(From.CameraSettings.SensitivityFactorPitch, this);

				PlayerCameraSettings.SensitivityFactor.SetManualFraction(1.0 - Alpha, this);
				PlayerCameraSettings.SensitivityFactorYaw.SetManualFraction(1.0 - Alpha, this);
				PlayerCameraSettings.SensitivityFactorPitch.SetManualFraction(1.0 - Alpha, this);
			}
			else if (!From.CameraSettings.bUseSensitivityFactor && To.CameraSettings.bUseSensitivityFactor)
			{
				PlayerCameraSettings.SensitivityFactor.Apply(To.CameraSettings.SensitivityFactor, this);
				PlayerCameraSettings.SensitivityFactorYaw.Apply(To.CameraSettings.SensitivityFactorYaw, this);
				PlayerCameraSettings.SensitivityFactorPitch.Apply(To.CameraSettings.SensitivityFactorPitch, this);

				PlayerCameraSettings.SensitivityFactor.SetManualFraction(Alpha, this);
				PlayerCameraSettings.SensitivityFactorYaw.SetManualFraction(Alpha, this);
				PlayerCameraSettings.SensitivityFactorPitch.SetManualFraction(Alpha, this);
			}
		}

		// Keep in view settings
		{
			BlendAndApplyFloatSetting(PlayerCameraSettings.KeepInView.MinDistance, Alpha, From.KeepInViewSettings.bUseMinDistance, From.KeepInViewSettings.MinDistance, To.KeepInViewSettings.bUseMinDistance, To.KeepInViewSettings.MinDistance);
			BlendAndApplyFloatSetting(PlayerCameraSettings.KeepInView.MaxDistance, Alpha, From.KeepInViewSettings.bUseMaxDistance, From.KeepInViewSettings.MaxDistance, To.KeepInViewSettings.bUseMaxDistance, To.KeepInViewSettings.MaxDistance);
			BlendAndApplyFloatSetting(PlayerCameraSettings.KeepInView.BufferDistance, Alpha, From.KeepInViewSettings.bUseBufferDistance, From.KeepInViewSettings.BufferDistance, To.KeepInViewSettings.bUseBufferDistance, To.KeepInViewSettings.BufferDistance);
		}
	}

	void BlendAndApplyFloatSetting(FHazeInstigatedCameraBlendFloat& BlendFloat, float Alpha, bool bUseFromValue, float FromValue, bool bUseToValue, float ToValue)
	{
		if (bUseFromValue && bUseToValue)
		{
			float Value = Math::Lerp(FromValue, ToValue, Alpha);
			BlendFloat.Apply(Value, this);
		}
		if (bUseFromValue && !bUseToValue)
		{
			BlendFloat.Apply(FromValue, this);
			BlendFloat.SetManualFraction(1.0 - Alpha, this);
		}

		else if (!bUseFromValue && bUseToValue)
		{
			BlendFloat.Apply(FromValue, this);
			BlendFloat.SetManualFraction(Alpha, this);
		}
	}

	void ApplySettings(const FFocusCameraBlendSplineKeySettings BlendedSettings)
	{
		const float BlendTime = SplineFocusCameraBlendComponent.FocusCameraBlendSettings.BlendIn;
		const EHazeCameraPriority Priority = EHazeCameraPriority::Medium;
		const int SubPriority = 0;

		UCameraSettings CameraSettings = UCameraSettings::GetSettings(Player);

		// Camera settings
		{
			if (BlendedSettings.CameraSettings.bUseFOV)
				CameraSettings.FOV.Apply(BlendedSettings.CameraSettings.FOV, this, BlendTime, Priority, SubPriority);

			if (BlendedSettings.CameraSettings.bUseSensitivityFactor)
			{
				CameraSettings.SensitivityFactor.Apply(BlendedSettings.CameraSettings.SensitivityFactor, this, BlendTime, Priority, SubPriority);
				CameraSettings.SensitivityFactorYaw.Apply(BlendedSettings.CameraSettings.SensitivityFactorYaw, this, BlendTime, Priority, SubPriority);
				CameraSettings.SensitivityFactorPitch.Apply(BlendedSettings.CameraSettings.SensitivityFactorPitch, this, BlendTime, Priority, SubPriority);
			}
		}

		// Keep in view
		{
			CameraSettings.KeepInView.MinDistance.Apply(BlendedSettings.KeepInViewSettings.MinDistance, this);
			CameraSettings.KeepInView.MaxDistance.Apply(BlendedSettings.KeepInViewSettings.MaxDistance, this);
			CameraSettings.KeepInView.BufferDistance.Apply(BlendedSettings.KeepInViewSettings.BufferDistance, this);
		}

		// Clamps
		if (BlendedSettings.ClampSettings.bUseClampSettings)
			CameraSettings.Clamps.Apply(BlendedSettings.ClampSettings.Settings, this, BlendTime, Priority, SubPriority);
	}

	EHazeSelectPlayer GetSelectPlayer() const property
	{
		return Player.IsMio() ? EHazeSelectPlayer::Mio : EHazeSelectPlayer::Zoe;
	}
}