class USkylineFlyingCarGunnerBazookaShootCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	USkylineFlyingCarGunnerComponent GunnerComponent;
	UPlayerTargetablesComponent TargetablesComponent;
	UPlayerAimingComponent AimingComponent;

	UHazeActorNetworkedSpawnPoolComponent BazookaRocketPool;

	UFlyingCarGunnerBazookaSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Owner);
		TargetablesComponent = UPlayerTargetablesComponent::Get(Owner);
		AimingComponent = UPlayerAimingComponent::Get(Owner);

		if (GunnerComponent.BazookaData.BazookaRocketClass.IsValid())
			BazookaRocketPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(GunnerComponent.BazookaData.BazookaRocketClass, Owner);

		Settings = GunnerComponent.BazookaData.Settings;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if (GunnerComponent.Car == nullptr)
			return false;

		if (GunnerComponent.GetGunnerState() != EFlyingCarGunnerState::Bazooka)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= Settings.ReloadTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (HasControl())
		{
			FAimingRay AimRay = AimingComponent.GetPlayerAimingRay();

			// Spawn new projectile
			FHazeActorSpawnParameters SpawnParams(Owner);
			SpawnParams.Location = GunnerComponent.Bazooka.ActorLocation + GunnerComponent.Bazooka.ActorForwardVector * 70 + GunnerComponent.Bazooka.ActorUpVector * 25;
			SpawnParams.Rotation = AimRay.Direction.Rotation();
			ASkylineFlyingCarBazookaRocket BazookaRocket = Cast<ASkylineFlyingCarBazookaRocket>(BazookaRocketPool.SpawnControl(SpawnParams));

			Crumb_ShootBazookaRocket(BazookaRocket, AimRay, GetLockedOnTarget());
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GunnerComponent.bReloadingBazooka = false;
		GunnerComponent.OnReloaded.Broadcast();
	}

	USkylineFlyingCarBazookaTargetableComponent GetLockedOnTarget() const
	{
		auto BazookaTargetable = TargetablesComponent.GetPrimaryTarget(USkylineFlyingCarBazookaTargetableComponent);
		if (BazookaTargetable != nullptr)
		{
			if (BazookaTargetable.IsLockedOn())
				return BazookaTargetable;
		}

		return nullptr;
	}

	UFUNCTION(CrumbFunction)
	void Crumb_ShootBazookaRocket(ASkylineFlyingCarBazookaRocket BazookaRocket, FAimingRay AimRay, USkylineFlyingCarBazookaTargetableComponent HomingTarget)
	{
		BazookaRocket.GunnerComponent = GunnerComponent;
		BazookaRocket.RemoveActorDisable(this);

		// Launch!
		FBazookaRocketLaunchParams LaunchParams;
		LaunchParams.AimDirection = AimRay.Direction;
		LaunchParams.BaseVelocity = GunnerComponent.Car.ActorVelocity;
		LaunchParams.SpeedRange = Settings.AdditiveMoveSpeed;
		LaunchParams.SpeedAccelerationDuration = Settings.MinToMaxSpeedAccelerationDuration;
		LaunchParams.Damage = Settings.Damage;
		LaunchParams.HomingTarget = HomingTarget;
		BazookaRocket.Launch(LaunchParams);

		BazookaRocket.OnRocketExplodedEvent.AddUFunction(this, n"OnRocketExploded");

		USkylineFlyingCarEventHandler::Trigger_OnBazookaShot(GunnerComponent.Car);

		// Juice
		Player.PlayCameraShake(GunnerComponent.BazookaData.ShootCameraShake, this);
		Player.PlayForceFeedback(GunnerComponent.BazookaData.ShootForceFeedbackEffect, false, false, this);

		// Start reloading
		GunnerComponent.bReloadingBazooka = true;
		GunnerComponent.OnReloading.Broadcast();
		USkylineFlyingCarEventHandler::Trigger_OnBazookaReload(GunnerComponent.Car);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRocketExploded(ASkylineFlyingCarBazookaRocket Rocket)
	{
		Rocket.AddActorDisable(this);
		BazookaRocketPool.UnSpawn(Rocket);
	}
}