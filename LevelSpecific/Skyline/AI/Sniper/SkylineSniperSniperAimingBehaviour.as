class USkylineSniperSniperAimingBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USkylineSniperAimingComponent AimingComp;
	USkylineSniperSettings SniperSettings;

	UBasicAIProjectileLauncherComponent Weapon;

	bool Decided = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		AimingComp = USkylineSniperAimingComponent::Get(Owner);
		SniperSettings = USkylineSniperSettings::GetSettings(Owner);

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

		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, SniperSettings.AimDuration + SniperSettings.AimFreezeDuration));	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AimingComp.EndAim();
		Cooldown.Set(SniperSettings.AimCooldown);
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

		if(TargetComp.HasValidTarget())
			AimingComp.SetAim(TargetComp.Target.ActorCenterLocation);
	}
}