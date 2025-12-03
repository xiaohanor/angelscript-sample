class UKiteFlightPlayerComponent : UActorComponent
{
	UPROPERTY()
	UAnimSequence FlyStartAnim;

	UPROPERTY()
	UAnimSequence FlyMH;

	UPROPERTY()
	UBlendSpace FlyBS;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> FlyCamShake;

	UPROPERTY()
	UForceFeedbackEffect BoostFF;

	UPROPERTY()
	TSubclassOf<AKiteFlightKiteCompanion> CompanionClass;

	UPROPERTY()
	UAnimSequence BoostAnim;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;

	bool bFlightActive = false;

	float CurrentBoostValue = 0.0;
	bool bRecentlyBoosted = false;

	EKiteFlightControlMode ControlMode = EKiteFlightControlMode::Movement;

	FVector InitialDirection;

	UHazeCrumbSyncedFloatComponent ForwardSpeedSyncComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Player);

		ForwardSpeedSyncComp = UHazeCrumbSyncedFloatComponent::GetOrCreate(Player, n"KiteFlightForwardSpeedSync");
	}

	void ActivateFlight(FVector Dir = FVector::ZeroVector)
	{
		if (Dir.Equals(FVector::ZeroVector))
			InitialDirection = Player.ViewRotation.ForwardVector;
		else
			InitialDirection = Dir;
			
		bFlightActive = true;

		TriggerBoost(2500.0);
	}

	void DeactivateFlight()
	{
		bFlightActive = false;

		// This needs to be here until we implement anims in ABP
		Player.StopSlotAnimation();

		const float BlendOutTime = Player.IsAnyCapabilityActive(n"Grapple") || Player.IsOnWalkableGround() ? 0.1 : 0.5;
		Player.StopBlendSpace(BlendOutTime);
	}

	void TriggerBoost(float BoostValue)
	{
		bRecentlyBoosted = true;
		CurrentBoostValue = Math::Clamp(CurrentBoostValue + BoostValue, 0.0, KiteFlight::GetMaxSpeedWithRubberbanding(Player) - KiteFlight::MinSpeed);

		FHazeAnimationDelegate BoostAnimFinishedDelegate;
		BoostAnimFinishedDelegate.BindUFunction(this, n"BoostAnimFinished");
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), BoostAnimFinishedDelegate, BoostAnim, BlendOutTime = .5);

		Player.PlayForceFeedback(BoostFF, false, true, this);

		UKiteFlightPlayerEffectEventEventHandler::Trigger_Boost(Player);
		UKiteTownVOEffectEventHandler::Trigger_FlightBoost(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}

	UFUNCTION()
	private void BoostAnimFinished()
	{
		if (bFlightActive)
			Player.PlayBlendSpace(FlyBS, BlendTime = 0.5);
	}

	float GetSpeedAlpha()
	{
		return Math::GetMappedRangeValueClamped(FVector2D(KiteFlight::MinSpeed, KiteFlight::GetMaxSpeedWithRubberbanding(Player)), FVector2D(0.0, 1.0), ForwardSpeedSyncComp.Value);
	}

	UFUNCTION(DevFunction)
	void ToggleAlternateControls()
	{
		if (ControlMode == EKiteFlightControlMode::Camera)
			ControlMode = EKiteFlightControlMode::Movement;
		else if (ControlMode == EKiteFlightControlMode::Movement)
			ControlMode = EKiteFlightControlMode::Camera;

		Print("" + ControlMode, 2.0, FLinearColor::Yellow);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float MaxSpeedMultiplier = KiteFlight::GetCurrentMaxSpeedMultiplier(Player);
		// PrintToScreen("" + Player + " " + MaxSpeedMultiplier);
	}
}

enum EKiteFlightControlMode
{
	Camera,
	Movement
}