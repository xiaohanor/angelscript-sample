class UCoastShoulderTurretCannonFireCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ACoastShoulderTurret Turret;

	UPlayerAimingComponent AimComp;
	UCoastShoulderTurretComponent TurretComp;
	UCoastShoulderTurretCannonAmmoComponent AmmoComp;
	UCameraUserComponent CameraUserComp;

	UCoastShoulderTurretCannonSettings GunSettings; 

	int CurrentShootIndex = 0;
	float ShootCooldown = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TurretComp = UCoastShoulderTurretComponent::Get(Player);
		AmmoComp = UCoastShoulderTurretCannonAmmoComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);

		Turret = TurretComp.Turret;

		GunSettings = UCoastShoulderTurretCannonSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Turret.IsAiming())
			return false;

		if(!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if(AmmoComp.CurrentAmmoCount <= 0)
			 return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Turret.IsAiming())
			return true;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		if(AmmoComp.CurrentAmmoCount <= 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Turret.bIsShooting = true;
		Turret.OnStartShooting.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Turret.bIsShooting = false;
		Turret.OnStoppedShooting.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(ShootCooldown > 0)
			ShootCooldown -= DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ShootCooldown <= 0)
			Shoot();
	}

	void Shoot()
	{
		CurrentShootIndex++;
		CurrentShootIndex = CurrentShootIndex%(GunSettings.ShootIndexMax+1);

		for(auto Gun : Turret.Guns)
		{
			if(CurrentShootIndex == Gun.ShootIndex)
			{
				FHazeTraceSettings Trace;
				Trace.TraceWithChannel(ECollisionChannel::WeaponTracePlayer);
				Trace.UseLine();

				FAimingResult AimTarget = AimComp.GetAimingTarget(Player);

				FVector Start = AimTarget.AimOrigin;
				FVector End = Start + (AimTarget.AimDirection * GunSettings.ShotMaxDistance);
				FVector ShotMuzzleLocation = GetMuzzleLocation(Gun.TurretSkelMeshComp);

				FHitResult StartToEndHit = Trace.QueryTraceSingle(Start, End);
				
				FHitResult CorrectHitResult;

				if(StartToEndHit.bBlockingHit)
				{
					CorrectHitResult = StartToEndHit;
					
					// Have to retrace to see if shot hits from muzzle because gun is offset
					FHitResult MuzzleToEndHit = Trace.QueryTraceSingle(ShotMuzzleLocation, StartToEndHit.ImpactPoint);
					if(MuzzleToEndHit.bBlockingHit)
					{
						CorrectHitResult = MuzzleToEndHit;
					}
				}

				if(CorrectHitResult.bBlockingHit)
				{
					End = CorrectHitResult.ImpactPoint;

					FCoastShoulderTurretShotImpactEffectParams ImpactParams;
					ImpactParams.ImpactPoint = CorrectHitResult.ImpactPoint;
					ImpactParams.ImpactNormal = CorrectHitResult.ImpactNormal;
					ImpactParams.HitComponent = CorrectHitResult.Component;
					UCoastShoulderTurretEffectHandler::Trigger_OnBulletImpact(Turret, ImpactParams);

					auto ResponseComp = UCoastShoulderTurretGunResponseComponent::Get(CorrectHitResult.Actor);
					// Hit something!
					if(ResponseComp != nullptr)
					{
						if(HasControl())
						{
							FCoastShoulderTurretBulletHitParams HitParams;
							HitParams.Damage = GunSettings.DamagePerSecond / GunSettings.FireRate / Turret.Guns.Num();
							HitParams.HitComponent = CorrectHitResult.Component;
							HitParams.ImpactNormal = CorrectHitResult.ImpactNormal;
							HitParams.ImpactPoint = CorrectHitResult.ImpactPoint;
							HitParams.PlayerInstigator = Player;

							ResponseComp.OnBulletHit.Broadcast(HitParams);
							Turret.OnShotHit.Broadcast();
						}
					}
				}

				FCoastShoulderTurretShotEffectParams ShotParams;
				ShotParams.TurretMesh = Gun.TurretSkelMeshComp;
				ShotParams.SocketName = TurretComp.MuzzleSocketName;
				ShotParams.ShotDirection = (End - ShotMuzzleLocation).GetSafeNormal();
				UCoastShoulderTurretEffectHandler::Trigger_OnBulletFired(Turret, ShotParams);

				Player.PlayCameraShake(GunSettings.ShotCameraShake, this);
				if(HasControl())
					CrumbSpendAmmo();
			}
		}
		ShootCooldown += (1.0 / GunSettings.FireRate);
		Player.PlayForceFeedback(GunSettings.ShotRumble, false, false, this, 1.0);
		Player.PlayForceFeedback(GunSettings.ShotTriggerRumble, false, false, this, 1.0);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbSpendAmmo()
	{
		AmmoComp.ChangeAmmo(AmmoComp.CurrentAmmoCount - 1);
	}

	FVector GetMuzzleLocation(UHazeSkeletalMeshComponentBase SkelMesh) const
	{
		return SkelMesh.GetSocketLocation(TurretComp.MuzzleSocketName);
	}
};