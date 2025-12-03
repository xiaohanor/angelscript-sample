class UAdultDragonAcidProjectileFireCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonAcidFire);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonAim);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	UPlayerAimingComponent AimComp;
	UPlayerAcidAdultDragonComponent DragonComp;
	UAdultDragonAcidProjectileComponent ProjectileComp;

	UAdultDragonAcidProjectileSettings ProjectileSettings;

	float TimeWhenShot;
	float DelayBeforeShoot = 0.15;
	int SpawnCounter = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerAcidAdultDragonComponent::Get(Player);
		ProjectileComp = UAdultDragonAcidProjectileComponent::Get(Player);

		ProjectileSettings = UAdultDragonAcidProjectileSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if (!DragonComp.WantsAiming())
			return false;

		if (Time::GetGameTimeSince(TimeWhenShot) < ProjectileSettings.Cooldown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > DelayBeforeShoot)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ProjectileComp.OnProjectileFired.Broadcast();
		TimeWhenShot = Time::GameTimeSeconds;

		FTransform TargetSocket = DragonComp.DragonMesh.GetSocketTransform(AdultDragonAcidBeam::ShootSocket);
		FVector Start = TargetSocket.TransformPosition(AdultDragonAcidBeam::ShootSocketOffset);

		if (!AimComp.IsAiming(Player))
			return;
		
		AAdultDragonAcidProjectile Proj = SpawnActor(ProjectileComp.AcidProjectileClass, Start, bDeferredSpawn = true);
		Proj.MakeNetworked(this, FNetworkIdentifierPart(SpawnCounter));
		SpawnCounter++;
		Proj.SetActorControlSide(Player);
		FAimingResult AimTarget = AimComp.GetAimingTarget(Player);
		Proj.Direction = AimTarget.AimDirection;
		Proj.Speed = ProjectileSettings.MoveSpeed;
		Proj.OwningPlayer = Player;
		Proj.OtherPlayer = Player.OtherPlayer;

		if (AimTarget.AutoAimTarget != nullptr)
		{
			FAcidHomingTargetParams HomingParams;
			HomingParams.HomingTarget = AimTarget.AutoAimTarget.Owner;
			HomingParams.HomingPointOffset = AimTarget.AutoAimTargetPoint - HomingParams.HomingTarget.ActorLocation;
			HomingParams.HomingCorrection = 40.0;
			Proj.HomingParams = HomingParams;
		}

		FAdultDragonAcidBoltFireParams Params;
		Params.DragonMesh = DragonComp.DragonMesh;
		FinishSpawningActor(Proj);
		UAdultDragonAcidProjectileEffectHandler::Trigger_AcidProjectileFire(Proj, Params);
		UAdultDragonAcidProjectileEffectHandler::Trigger_AcidProjectileFire(Player, Params);

		if (!SceneView::IsFullScreen())
			Player.PlayCameraShake(DragonComp.AcidProjectileCameraShake, this);

		Player.PlayForceFeedback(DragonComp.AcidFireRumble, false, false, this);
	}
};