class UAdultDragonAcidChargeProjectileFireCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonAcidFire);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonAim);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	UPlayerAimingComponent AimComp;
	UPlayerAcidAdultDragonComponent DragonComp;
	UAdultDragonAcidChargeProjectileComponent ChargeComp;

	UAdultDragonAcidChargeProjectileSettings ProjectileSettings;

	float NextFireTimeAllowed;
	bool bBroadcastedReady;

	FInstigator ChargeInstigator = n"AcidCharge";
	FInstigator FullChargeInstigator = n"AcidFullCharge";

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerAcidAdultDragonComponent::Get(Player);
		ChargeComp = UAdultDragonAcidChargeProjectileComponent::Get(Player);

		ProjectileSettings = UAdultDragonAcidChargeProjectileSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		if (!DragonComp.WantsAiming())
			return false;

		if (!AimComp.IsAiming())
			return false;

		if (DeactiveDuration < ProjectileSettings.Cooldown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (WasActionStopped(ActionNames::PrimaryLevelAbility))
			return true;

		if (ProjectileSettings.bAutoShootOnFullCharge && ActiveDuration > ProjectileSettings.MaxChargeDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ChargeComp.bHasSuccessfullyShot = false;

		ChargeComp.ChargeAnimationParams.bIsCharging = true;
		ChargeComp.ChargeAnimationParams.bShootSuccess = false;
		ChargeComp.ChargeAnimationParams.ChargeAlpha = 0;
		Player.PlayForceFeedback(ChargeComp.ChargeForceFeedbackEffect, false, true, this, 1);

		FAdultDragonAcidChargeProjectileStartedParams Params;
		Params.DragonMesh = DragonComp.DragonMesh;
		UAdultDragonAcidChargeProjectileEffectHandler::Trigger_AcidChargeProjectileChargeStarted(Player, Params);

		bBroadcastedReady = false;
		if (DragonComp.DragonMesh.CanRequestAdditiveFeature())
			DragonComp.DragonMesh.RequestAdditiveFeature(n"AcidAdultDragonShoot", this);

		Player.ApplyCameraSettings(ChargeComp.ChargeCameraSettings, UAdultDragonAcidChargeProjectileSettings::GetSettings(Player).MaxChargeDuration, ChargeInstigator, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bool bSuccessfullyShot = ActiveDuration >= ProjectileSettings.MaxChargeDuration;

		Player.StopForceFeedback(this);
		ChargeComp.ChargeAnimationParams.ChargeAlpha = 0;
		ChargeComp.ChargeAnimationParams.bIsCharging = false;
		ChargeComp.ChargeAnimationParams.bShootSuccess = bSuccessfullyShot;

		if (bSuccessfullyShot && AimComp.IsAiming())
		{
			FVector Direction;
			FAimingResult AimTarget = AimComp.GetAimingTarget(Player);
			if (AimTarget.AutoAimTarget != nullptr)
				Direction = (AimTarget.AutoAimTarget.WorldLocation - DragonComp.DragonMesh.GetSocketLocation(ProjectileSettings.ShootSocket)).GetSafeNormal();
			else
				Direction = Player.ActorForwardVector;

			FVector Start = DragonComp.DragonMesh.GetSocketLocation(ProjectileSettings.ShootSocket);

			auto Projectile = SpawnActor(ChargeComp.AcidProjectileClass, Start, FRotator::ZeroRotator, NAME_None, true);
			Projectile.Direction = Direction;
			Projectile.Speed = ProjectileSettings.MoveSpeed;
			FinishSpawningActor(Projectile);

			Player.PlayCameraShake(ChargeComp.ShotSuccessCameraShake, this);
			Player.PlayForceFeedback(ChargeComp.ShotSuccessForceFeedback, false, true, this);
			ChargeComp.bHasSuccessfullyShot = true;
		}

		if (!Player.IsPlayerDead() && !Player.IsPlayerRespawning() && DragonComp.DragonMesh.CanRequestAdditiveFeature())
			DragonComp.DragonMesh.RequestAdditiveFeature(n"AcidAdultDragonShoot", this);

		FAdultDragonAcidChargeProjectileReleasedParams Params;
		Params.DragonMesh = DragonComp.DragonMesh;
		UAdultDragonAcidChargeProjectileEffectHandler::Trigger_AcidChargeProjectileChargeReleased(Player, Params);
		Player.ClearCameraSettingsByInstigator(ChargeInstigator);
		Player.ClearCameraSettingsByInstigator(FullChargeInstigator);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration >= ProjectileSettings.MaxChargeDuration && !bBroadcastedReady)
		{
			bBroadcastedReady = true;
			ChargeComp.OnAcidProjectileReady.Broadcast();
			Player.ApplyCameraSettings(ChargeComp.FullChargeCameraSettings, 0.5, FullChargeInstigator, EHazeCameraPriority::High);
			Player.ApplyCameraSettings(ChargeComp.FullChargeCameraSettings, 0.5, FullChargeInstigator, EHazeCameraPriority::High);

			FAdultDragonAcidChargeProjectileFinishedParams Params;
			Params.DragonMesh = DragonComp.DragonMesh;
			UAdultDragonAcidChargeProjectileEffectHandler::Trigger_AcidChargeProjectileChargeFinished(Player, Params);
			Player.ApplyCameraSettings(ChargeComp.FullChargeCameraSettings, 0.6, FullChargeInstigator, EHazeCameraPriority::High);
		}

		float ChargeAlpha = Math::Saturate(ActiveDuration / ProjectileSettings.MaxChargeDuration);
		// if (ChargeAlpha >= UAdultDragonAcidChargeProjectileSettings::GetSettings(Player).MaxChargeDuration)
		// {
		// 	float Frac = (ChargeAlpha - UAdultDragonAcidChargeProjectileSettings::GetSettings(Player).MaxChargeDuration) / UAdultDragonAcidChargeProjectileSettings::GetSettings(Player).MaxChargeDuration;
		// 	Player.ApplyManualFractionToCameraSettings(Frac, ChargeInstigator);
		// }

		ChargeComp.ChargeAnimationParams.ChargeAlpha = ChargeAlpha;

		if (DragonComp.DragonMesh.CanRequestAdditiveFeature())
			DragonComp.DragonMesh.RequestAdditiveFeature(n"AcidAdultDragonShoot", this);
	}
};