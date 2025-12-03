class UFlyingCarGunnerShootProjectileCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(FlyingCarTags::FlyingCarGunner);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	USkylineFlyingCarGunnerComponent GunnerComponent;
	ASkylineFlyingCarGun Gun;
	UFlyingCarGunnerWeaponSettings Settings;

	float CoolDownTime = 0.0;

	UPlayerAimingComponent PlayerAimingComponent;
	UPlayerTargetablesComponent PlayerTargetablesComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Owner);
		PlayerAimingComponent = UPlayerAimingComponent::Get(Owner);
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Owner);
		Settings = UFlyingCarGunnerWeaponSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return false;
		// if(!WasActionStarted(ActionNames::PrimaryLevelAbility))
		// 	return false;

		// if (GunnerComponent.Car == nullptr)
		// 	return false;

		// return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (GunnerComponent.Car == nullptr)
	        return true;

		if(CoolDownTime > 0)
			return false;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Gun = GunnerComponent.Car.Gun;
		Gun.ProjectileLauncherComponent.AdditionalProjectileIgnoreActors.Add(Gun.CarOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CoolDownTime = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CoolDownTime -= DeltaTime;

		if(CoolDownTime < 0 && IsActioning(ActionNames::PrimaryLevelAbility))
		{
			float Alpha = Math::Min(ActiveDuration / Settings.TimeToMinCooldown, 1.0);
			CoolDownTime += Math::Lerp(Settings.CooldownMin, Settings.CooldownMax, Alpha);

			auto EndTraceSettings = Trace::InitChannel(GunnerComponent.TraceChannel);
			EndTraceSettings.IgnoreActor(GunnerComponent.Car);
			EndTraceSettings.IgnoreActor(GunnerComponent.Gun);

			// Audio needs physmat
			EndTraceSettings.SetReturnPhysMaterial(true);

			auto Aim = PlayerAimingComponent.GetPlayerAimingRay();

			FVector TargetLocation = Aim.Origin + Aim.Direction * 50000.0;
			
			FHitResult ShootToHit = EndTraceSettings.QueryTraceSingle(Aim.Origin, TargetLocation);

			if(ShootToHit.bBlockingHit)
			{
				TargetLocation = ShootToHit.Location;	
			}

			auto Target = PlayerTargetablesComponent.GetPrimaryTargetForCategory(n"AutoAim");
			if (Target != nullptr)
			{
//				Debug::DrawDebugPoint(Target.WorldLocation, 300.0, FLinearColor::Green, 0.0);
				TargetLocation = Target.WorldLocation;
			}

			// Launch projectile
			// TODO: Needs networking
			FVector Direction = (TargetLocation - Gun.ProjectileLauncherComponent.WorldLocation).GetSafeNormal();
			auto Projectile = Gun.ProjectileLauncherComponent.Launch(Direction * Gun.ProjectileLauncherComponent.LaunchSpeed + Gun.CarOwner.ActorVelocity, Direction.Rotation());

			if (Target != nullptr)
			{
				auto HomingProjectileComponent = UBasicAIHomingProjectileComponent::Get(Projectile.Owner);
				if (HomingProjectileComponent != nullptr)
				{
					HomingProjectileComponent.Target = Cast<AHazeActor>(Target.Owner);
				}
			}
		}
	}

};