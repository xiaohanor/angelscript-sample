class UTeenDragonAirGlideComponent : UActorComponent
{
	default TickGroup = ETickingGroup::TG_LastDemotable;

	UPROPERTY(Category = "Settings")
	UTeenDragonAirGlideSettings AirGlideSettings;

	UPROPERTY(Category = "Camera")
	UHazeCameraSettingsDataAsset HoverCamSettings;

	UPROPERTY(Category = "Camera")
	UHazeCameraSettingsDataAsset RingBoostCamSettings;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> StartGlideCameraShake;

	// Scaled by speed alpha and the curve in the settings
	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> ContinuousGlideCameraShake;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> RingBoostStartCameraShake;

	UPROPERTY(Category = "Haptic Feedback")
	UForceFeedbackEffect StartGlideForceFeedback;

	TOptional<FSummitAirGlideBoostRingParams> ActiveRingParams;

	bool bIsAirGliding = false;
	bool bInAirCurrent = false;
	bool bActivatedWithInitialBoost = false;
	bool bInitialAirBoostAvailable = true;

	private AHazePlayerCharacter PlayerOwner;
	private UPlayerAcidTeenDragonComponent DragonComp;

	const float BoostRingAnimationDuration = 1.46;

	private bool bHasUpdatedGlideVerticalSpeedThisFrame = false;
	private float GlideVerticalSpeed = 0.0;
	float BoostRingSpeed = 0.0;

	TArray<ASummitAirCurrent> OverlappedAirCurrents;
	TArray<ASummitAirCurrent> ActiveAirCurrents;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerOwner.ApplyDefaultSettings(AirGlideSettings);

		DragonComp = UPlayerAcidTeenDragonComponent::Get(PlayerOwner);
	}

	/** Tick group last demotable */
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bHasUpdatedGlideVerticalSpeedThisFrame = false;
	}

	void RequestRingBoost(FSummitAirGlideBoostRingParams& Params)
	{
		Params.BoostTimer = 0.0;

		ActiveRingParams.Set(Params);

		UTeenDragonAirGlideEventHandler::Trigger_BoostRingStarted(PlayerOwner);
		UDragonMovementAudioEventHandler::Trigger_AcidTeenBoostRingStart(DragonComp.GetTeenDragon());
	}

	void ClearRingBoost(FSummitAirGlideBoostRingParams Params)
	{
		PlayerOwner.StopCameraShakeByInstigator(Params.BoostRing);
		PlayerOwner.ClearCameraSettingsByInstigator(Params.BoostRing, AirGlideSettings.RingBoostCameraBlendOutTime);
	}

	void ApplyGlideHaptic(float GlideSpeed)
	{
		if(DragonComp.AimMode == ETeenDragonAcidAimMode::LeftTriggerMode)
			return;

		FHazeFrameForceFeedback ForceFeedBack;

		float SpeedAlpha = Math::GetPercentageBetweenClamped(0, AirGlideSettings.GlideHorizontalMaxMoveSpeed, GlideSpeed);
		float BaseValue = 0.05 * SpeedAlpha;
		float NoiseBased = 0.1 * ((Math::PerlinNoise1D(Time::GameTimeSeconds * 2.5) + 1.0) * 0.5);
		
		float MotorStrength = BaseValue + NoiseBased;

		ForceFeedBack.LeftTrigger = MotorStrength;	
		PlayerOwner.SetFrameForceFeedback(ForceFeedBack);
	}

	void AlterGlideVerticalSpeed(float SpeedChange)
	{
		SetGlideVerticalSpeed(GlideVerticalSpeed + SpeedChange);
	}

	void SetGlideVerticalSpeed(float NewSpeed)
	{
		if(bHasUpdatedGlideVerticalSpeedThisFrame)
			return;

		GlideVerticalSpeed = NewSpeed;
		bHasUpdatedGlideVerticalSpeedThisFrame = true;
	}

	float GetGlideVerticalSpeed() const
	{
		return GlideVerticalSpeed;
	}

	bool HasUpdatedGlideVerticalSpeedThisFrame() const
	{
		return bHasUpdatedGlideVerticalSpeedThisFrame;
	}
};