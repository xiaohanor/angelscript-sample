class UAdultDragonSpikeFireCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonSpikeFire);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonAim);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	UPlayerAimingComponent AimComp;
	UPlayerTailAdultDragonComponent DragonComp;

	UAdultDragonSpikeProjectileSettings ProjectileSettings;

	float NextFireTimeAllowed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerTailAdultDragonComponent::Get(Player);

		ProjectileSettings = UAdultDragonSpikeProjectileSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if(!DragonComp.WantsAiming())
			return false;

		if (Time::GameTimeSeconds < NextFireTimeAllowed)
			return false;
		
		// OBS! TEMPORARELY DISABLED :)))
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		NextFireTimeAllowed = Time::GameTimeSeconds + ProjectileSettings.Cooldown;

		FTransform TargetSocket = DragonComp.DragonMesh.GetSocketTransform(AdultDragonAcidBeam::ShootSocket);
		FVector Start = TargetSocket.TransformPosition(AdultDragonAcidBeam::ShootSocketOffset);

		AAdultDragonSpikeProjectile Proj = SpawnActor(DragonComp.SpikeProjectileClass, Start, bDeferredSpawn = true);
		FAimingResult AimTarget = AimComp.GetAimingTarget(Player);
		Proj.Direction = AimTarget.AimDirection;
		Proj.Speed = ProjectileSettings.MoveSpeed;
		Proj.OwningPlayer = Player;
		Proj.OtherPlayer = Player.OtherPlayer;

		if (AimTarget.AutoAimTarget != nullptr)
		{
			FSpikeHomingTargetParams HomingParams;
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
	}
}