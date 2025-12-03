class UCoastShoulderTurretLaserShootingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ACoastShoulderTurret Turret;

	UPlayerAimingComponent AimComp;
	UCoastShoulderTurretComponent TurretComp;
	UCoastShoulderTurretLaserOverheatComponent OverheatComp;
	UCameraUserComponent CameraUserComp;

	UCoastShoulderTurretLaserSettings LaserSettings; 

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TurretComp = UCoastShoulderTurretComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
		OverheatComp = UCoastShoulderTurretLaserOverheatComponent::Get(Player);

		Turret = TurretComp.Turret;

		LaserSettings = UCoastShoulderTurretLaserSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Turret.IsAiming())
			return false;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		if((OverheatComp.CurrentHeatLevel / LaserSettings.HeatLevelMax) > LaserSettings.HeatPercentageThresholdToFire)
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

		if(OverheatComp.CurrentHeatLevel >= LaserSettings.HeatLevelMax)
			 return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Turret.bIsShooting = true;
		Player.PlayCameraShake(LaserSettings.ShootingCameraShake, this);
		Turret.OnStartShooting.Broadcast();

		Player.PlayForceFeedback(LaserSettings.ShootingRumble, true, false, this);
		Player.PlayForceFeedback(LaserSettings.ShootingTriggerRumble, true, false, this);

		for(auto Gun : Turret.Guns)
		{
			FCoastShoulderTurretLaserToggleEffectParams Params;
			Params.TurretMesh = Gun.TurretSkelMeshComp;
			Params.SocketName = TurretComp.MuzzleSocketName;
			UCoastShoulderTurretLaserEffectHandler::Trigger_OnStartShooting(Turret, Params);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Turret.bIsShooting = false;
		Player.StopCameraShakeByInstigator(this);
		Turret.OnStoppedShooting.Broadcast();

		Player.StopForceFeedback(this);

		for(auto Gun : Turret.Guns)
		{
			FCoastShoulderTurretLaserToggleEffectParams Params;
			Params.TurretMesh = Gun.TurretSkelMeshComp;
			Params.SocketName = TurretComp.MuzzleSocketName;
			UCoastShoulderTurretLaserEffectHandler::Trigger_OnStoppedShooting(Turret, Params);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Shoot(DeltaTime);
	}

	void Shoot(float DeltaTime)
	{
		for(auto Gun : Turret.Guns)
		{
			FHazeTraceSettings Trace;
			Trace.TraceWithChannel(ECollisionChannel::WeaponTracePlayer);
			Trace.UseLine();

			FAimingResult AimTarget = AimComp.GetAimingTarget(Player);

			FVector Start = AimTarget.AimOrigin;
			FVector End = Start + (AimTarget.AimDirection * LaserSettings.LaserMaxDistance);
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
				
				FCoastShoulderTurretLaserImpactEffectParams ImpactParams;
				ImpactParams.HitComponent = CorrectHitResult.Component;
				ImpactParams.ImpactNormal = CorrectHitResult.ImpactNormal;
				ImpactParams.ImpactPoint = CorrectHitResult.ImpactPoint;
				UCoastShoulderTurretLaserEffectHandler::Trigger_WhileLaserImpacting(Turret, ImpactParams);

				auto ResponseComp = UCoastShoulderTurretGunResponseComponent::Get(CorrectHitResult.Actor);
				// Hit something!
				if(ResponseComp != nullptr)
				{
					if(HasControl())
					{
						FCoastShoulderTurretBulletHitParams HitParams;
						HitParams.Damage = LaserSettings.DamagePerSecond / Turret.Guns.Num() * DeltaTime;
						HitParams.HitComponent = CorrectHitResult.Component;
						HitParams.ImpactNormal = CorrectHitResult.ImpactNormal;
						HitParams.ImpactPoint = CorrectHitResult.ImpactPoint;
						HitParams.PlayerInstigator = Player;

						ResponseComp.OnBulletHit.Broadcast(HitParams);
						Turret.OnShotHit.Broadcast();
					}
				}
			}

			FCoastShoulderturretLaserShootingEffectParams ShootingParams;
			ShootingParams.LaserStart = ShotMuzzleLocation;
			ShootingParams.LaserEnd = End;
			UCoastShoulderTurretLaserEffectHandler::Trigger_WhileLaserShooting(Turret, ShootingParams);
		}
		OverheatComp.SetHeatLevel(OverheatComp.CurrentHeatLevel + LaserSettings.HeatGainedPerSecond * DeltaTime);
		OverheatComp.TimeLastShot = Time::GameTimeSeconds;
	}

	FVector GetMuzzleLocation(UHazeSkeletalMeshComponentBase SkelMesh) const
	{
		return SkelMesh.GetSocketLocation(TurretComp.MuzzleSocketName);
	}
};