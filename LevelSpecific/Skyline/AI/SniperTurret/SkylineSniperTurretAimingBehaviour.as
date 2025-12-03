class USkylineSniperTurretAimingBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USkylineSniperTurretAimingComponent AimingComp;
	USkylineSniperTurretSettings SniperSettings;

	UBasicAIProjectileLauncherComponent Weapon;
	UTargetTrailComponent TrailComp;

	AHazeActor Target;
	bool Decided = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		AimingComp = USkylineSniperTurretAimingComponent::Get(Owner);
		SniperSettings = USkylineSniperTurretSettings::GetSettings(Owner);

		Weapon = UBasicAIProjectileLauncherComponent::Get(Owner);
		if (Weapon == nullptr)
		{
			UBasicAIWeaponWielderComponent WielderComp = UBasicAIWeaponWielderComponent::Get(Owner);
			if (WielderComp != nullptr) 
			{
				if (WielderComp.Weapon != nullptr)
					Weapon = UBasicAIProjectileLauncherComponent::Get(WielderComp.Weapon);
				WielderComp.OnWieldWeapon.AddUFunction(this, n"OnWieldWeapon");
			}
		}

		UTargetTrailComponent::GetOrCreate(Game::Mio);
		UTargetTrailComponent::GetOrCreate(Game::Zoe);
	}

	UFUNCTION()
	private void OnWieldWeapon(ABasicAIWeapon WieldedWeapon)
	{
		if (WieldedWeapon == nullptr)
			return;
		UBasicAIProjectileLauncherComponent NewWeapon = UBasicAIProjectileLauncherComponent::Get(WieldedWeapon);
		if (NewWeapon != nullptr)
		{
			Weapon = NewWeapon;
			Weapon.SetWielder(Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(TargetComp.Target == nullptr)
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, SniperSettings.AttackRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration >= SniperSettings.AimDuration + SniperSettings.AimFreezeDuration)
			return true;
		if(TargetComp.Target == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AimingComp.StartAim();
		Decided = false;
		Target = TargetComp.Target;

		TrailComp = UTargetTrailComponent::GetOrCreate(Target);
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, SniperSettings.AimDuration + SniperSettings.AimFreezeDuration));	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AimingComp.EndAim();

		float DistanceMultiplier = Math::Clamp(Target.GetDistanceTo(Owner) / SniperSettings.AimFreezeDurationMultiplierDistance, 1, 1);
		Cooldown.Set(SniperSettings.AimCooldown * DistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(ActiveDuration > SniperSettings.AimDuration)
		{
			if(!Decided)
			{
				AimingComp.DecidedAim();
				Decided = true;
			}
			return;
		}

		if(TargetComp.IsValidTarget(Target))
		{
			FVector EndLocation = TrailComp.GetTrailLocation(0) + Target.ActorCenterLocation - Target.ActorLocation;
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
			Trace.UseLine();
			Trace.IgnoreActor(Owner);
			FVector Dir = (EndLocation - Weapon.LaunchLocation).GetSafeNormal();
			FHitResult Hit = Trace.QueryTraceSingle(Weapon.LaunchLocation, Weapon.LaunchLocation + Dir * 30000);
			if(Hit.bBlockingHit)
				EndLocation = Hit.Location;
			AimingComp.SetAim(Weapon.LaunchLocation, EndLocation);
		}
	}
}