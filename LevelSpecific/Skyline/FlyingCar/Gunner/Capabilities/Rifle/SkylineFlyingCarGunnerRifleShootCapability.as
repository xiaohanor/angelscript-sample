class UFlyingCarGunnerRifleShootCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(FlyingCarTags::FlyingCarGunner);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	USkylineFlyingCarGunnerComponent GunnerComponent;
	UFlyingCarGunnerRifleSettings Settings;

	float CoolDownTime = 0.0;

	UPlayerAimingComponent PlayerAimingComponent;
	UPlayerTargetablesComponent PlayerTargetablesComponent;

	UCameraSettings CameraSettings;
	UCameraShakeBase ShootingCameraBase = nullptr;

	float ShotTimer;

	int Clip;
	float ReloadStartTimeStamp;

	// It's for audio, don't even worry 'bout it
	const float ProjectileFlybyMaxAngle = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Owner);
		PlayerAimingComponent = UPlayerAimingComponent::Get(Owner);
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Owner);

		Settings = GunnerComponent.RifleData.Settings;
		CameraSettings = UCameraSettings::GetSettings(Player);

		ReloadClip();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if (GunnerComponent.Car == nullptr)
			return false;

		if (GunnerComponent.GetGunnerState() != EFlyingCarGunnerState::Rifle)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GunnerComponent.Car == nullptr)
	        return true;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		if (GunnerComponent.GetGunnerState() != EFlyingCarGunnerState::Rifle)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ShotTimer = 0.0;

		StartShootingFOVDecrease();
		GunnerComponent.bShooting = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ClearShootingFOV();
		GunnerComponent.bShooting = false;
	}

	// Eman TODO: SO TEMP GROOSS 
	// Move to reload capabilty
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (GunnerComponent.IsSittingInsideCar() && Clip < Settings.ClipSize)
			ReloadClip();

		if (IsBlocked())
			return;

		if (WasActionStarted(ActionNames::MovementDash) && !GunnerComponent.bReloadingRifle && Clip != Settings.ClipSize)
			Clip = 0;

		if (Clip <= 0)
		{
			if (GunnerComponent.bReloadingRifle)
			{
				float ReloadTimer = Time::GameTimeSeconds - ReloadStartTimeStamp;
				if (ReloadTimer >= Settings.ReloadTime)
				{
					ReloadClip();
					GunnerComponent.bReloadingRifle = false;
					ReloadStartTimeStamp = 0;

					if (IsActive())
					{
						StartShootingFOVDecrease();
						GunnerComponent.bShooting = true;
					}

					Player.SetFrameForceFeedback(1, 1, 1, 1);
				}
				else
				{
					// Reloadin...
					float Strength = Math::Abs(Math::PerlinNoise1D(Time::GameTimeSeconds * 2)) * 0.4;
					Player.SetFrameForceFeedback(0.1, 0.2, 0, 0.1, Strength);
				}
			}
			else
			{
				ResetShotTimer();
				ReloadStartTimeStamp = Time::GameTimeSeconds;
				GunnerComponent.bReloadingRifle = true;

				ClearShootingFOV();
				GunnerComponent.bShooting = false;

				GunnerComponent.OnReloading.Broadcast();
				USkylineFlyingCarEventHandler::Trigger_OnRifleReload(GunnerComponent.Car);
			}
		}

		GunnerComponent.RifleClipFraction = (float(Clip) / float(Settings.ClipSize));

		// FString AmmoString = GunnerComponent.bReloadingRifle ? "reloading" : String::Conv_IntToString(Clip) + "/" + String::Conv_IntToString(Settings.ClipSize);
		// PrintScaled(AmmoString, 0, FLinearColor::Green, 5);
		// Debug::DrawDebugString(GunnerComponent.Gun.ActorLocation, AmmoString, FLinearColor::White, Scale = 2, ScreenSpaceOffset = FVector2D(50, 0));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Clip > 0)
		{
			TickShooting(DeltaTime);

			float Strength = Math::Abs(Math::Min(1.0, ActiveDuration));
			FHazeFrameForceFeedback ForceFeedback;
			ForceFeedback.RightMotor = 0.4;
			ForceFeedback.RightTrigger = 0.4;
			Player.SetFrameForceFeedback(ForceFeedback, Strength);
		}
	}

	// Reload timer completed, fill'er up!
	void ReloadClip()
	{
		Clip = Settings.ClipSize;

		GunnerComponent.OnReloaded.Broadcast();
	}

	void TickShooting(float DeltaTime)
	{
		if (ShotTimer <= 0)
		{
			ResetShotTimer();

			FAimingRay AimRay = PlayerAimingComponent.GetPlayerAimingRay();
			FVector TargetLocation = AimRay.Origin + AimRay.Direction * Settings.Range;
			FVector HitNormal = FVector::ZeroVector;

			if (HasControl())
			{
				FHazeTraceSettings Trace = Trace::InitChannel(GunnerComponent.TraceChannel);
				Trace.IgnorePlayers();
				Trace.IgnoreActor(GunnerComponent.Car);
				Trace.IgnoreActor(GunnerComponent.Gun);

				// Audio needs physmat
				Trace.SetReturnPhysMaterial(true);

				// Eman TODO: Do auto aiming when aiming down the sights instead
				// If there is one, use targetable's location instead
				// UTargetableComponent TargetableComponent = PlayerTargetablesComponent.GetPrimaryTargetForCategory(n"AutoAim");
				// if (TargetableComponent != nullptr)
				// 	TargetLocation = TargetableComponent.WorldLocation;

				FHitResult HitResult = Trace.QueryTraceSingle(AimRay.Origin, TargetLocation);
				if (HitResult.bBlockingHit)
				{
					TargetLocation = HitResult.ImpactPoint;
					HitNormal = HitResult.ImpactNormal;

					// Deal damage
					if (HitResult.Actor != nullptr)
					{
						// Eman TODO: Add gun repsponse components to these fuckers instead
						if (UPlayerHealthComponent::Get(HitResult.Actor) != nullptr || UBasicAIHealthComponent::Get(HitResult.Actor) != nullptr)
						{
							CrumbDealManualDamage(HitResult);
						}
						else
						{
							USkylineFlyingCarGunResponseComponent GunResponseComponent = USkylineFlyingCarGunResponseComponent::Get(HitResult.Actor);
							if (GunResponseComponent != nullptr)
							{
								CrumbDealResponseComponentDamage(GunResponseComponent, HitResult);
							}
						}
					}

					// Trigger effect event
					CrumbOnProjectileHit(HitResult);
				}
			}

			// Trigger effect event
			FSkylineFlyingCarTurretGunshot Gunshot;
			// Gunshot.Origin = GunnerComponent.Gun.ProjectileLauncherComponent.WorldLocation;
			Gunshot.Origin = GunnerComponent.Rifle.ActorLocation + GunnerComponent.Rifle.ActorForwardVector * 50 + GunnerComponent.Rifle.ActorUpVector * 10;

			FVector Direction = (TargetLocation - Gunshot.Origin);
			Gunshot.TravelTime = Settings.BulletTravelTime.Lerp(Math::Saturate(Direction.Size() / Settings.Range));

			// Add some noise to effect, spread more the further away the target is
			FVector2D Random2DVector = Math::RandPointInCircle(Direction.Size() * Settings.Spread);
			FVector Noise = Player.ViewRotation.UpVector * Random2DVector.Y + Player.ViewRotation.RightVector * Random2DVector.X;
			Gunshot.Target = TargetLocation + Noise;

			Gunshot.ImpactNormal = HitNormal.IsZero() ?
				-Direction.GetSafeNormal() :
				HitNormal;

			Gunshot.OverheatAmount = GunnerComponent.RifleClipFraction;

			USkylineFlyingCarEventHandler::Trigger_OnTurretGunShot(GunnerComponent.Car, Gunshot);			

			const FVector ToZoeViewPoint = (Game::GetZoe().GetViewLocation() - GunnerComponent.Gun.GetActorLocation()).GetSafeNormal();
			const float FlybyDot = ToZoeViewPoint.DotProduct(Direction.GetSafeNormal());	

			if(FlybyDot >= ProjectileFlybyMaxAngle)
			{
				FSkylineFlyingCarTurretProjectileFlyby FlybyData;
				FlybyData.FlybyDistanceSigned = Math::GetMappedRangeValueClamped(FVector2D(1.0, ProjectileFlybyMaxAngle), FVector2D(1.0, 0.0), FlybyDot);								
				FlybyData.FlybyDistanceNormalized = 1 - FlybyData.FlybyDistanceSigned;

				const float Sign = Math::Sign(Direction.GetSafeNormal().DotProduct(Game::GetZoe().GetViewRotation().RightVector));
				FlybyData.FlybyDistanceSigned *= Sign;

				USkylineFlyingCarEventHandler::Trigger_OnTurretProjectileFlyby(GunnerComponent.Car, FlybyData);
			}

			Clip -= 1;
		}
		else
		{
			ShotTimer -= DeltaTime;
		}
	}

	void StartShootingFOVDecrease()
	{
		float MaxShootingTime = 1.0 + Settings.ClipSize / Settings.RateOfFire;
		CameraSettings.FOV.ApplyAsAdditive(-5, this, MaxShootingTime, EHazeCameraPriority::High);

		ShootingCameraBase = Player.PlayCameraShake(GunnerComponent.RifleData.ShootingCameraShakeClass, this, 0.5);
	}

	void ClearShootingFOV()
	{
		CameraSettings.FOV.Clear(this, 1);

		if (ShootingCameraBase != nullptr)
			Player.StopCameraShakeByInstigator(this);
	}

	void ResetShotTimer()
	{
		ShotTimer = 1.0 / Settings.RateOfFire;
	}

	UFUNCTION(CrumbFunction)
	void CrumbDealManualDamage(FHitResult HitResult)
	{
		BasicAIProjectile::DealDamage(HitResult, Settings.Damage.Rand(), EDamageType::Projectile, Player, FPlayerDeathDamageParams(HitResult.ImpactPoint, 0.1));

		HitMark(HitResult);
	}

	UFUNCTION(CrumbFunction)
	void CrumbDealResponseComponentDamage(USkylineFlyingCarGunResponseComponent GunResponseComponent, FHitResult HitResult)
	{
		FSkylineFlyingCarGunHit HitInfo;
		HitInfo.Damage = Settings.Damage.Rand();
		HitInfo.WorldImpactLocation = HitResult.ImpactPoint;
		HitInfo.WorldImpactNormal = HitResult.ImpactNormal;
		HitInfo.bControlSide = HasControl();

		GunResponseComponent.OnHitEvent.Broadcast(HitInfo);

		HitMark(HitResult);
	}

	UFUNCTION(CrumbFunction)
	void CrumbOnProjectileHit(const FHitResult& Hit)
	{
		FSkylineFlyingCarTurretProjectileImpact ImpactData;	
		ImpactData.HitActor = Cast<AHazeActor>(Hit.Actor);
		ImpactData.ImpactLocation = Hit.Location;
		ImpactData.ImpactNormal = Hit.ImpactNormal;
		ImpactData.ImpactPhysMat = Hit.PhysMaterial;		

		USkylineFlyingCarEventHandler::Trigger_OnTurretProjectileHit(GunnerComponent.Car, ImpactData);
	}

	void HitMark(FHitResult HitResult)
	{
		if (HitResult.Actor == nullptr)
			return;

		FlyingCarRifle::AddHitMarker(GunnerComponent, HitResult);
		Player.SetFrameForceFeedback(0.5, 0.0, 0.8, 1.0);
	}
}