class UEnforcerRocketLauncherRecoveryBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	private float RecoveryDuration;
	private bool Initialized;

	UFitnessStrafingComponent FitnessStrafingComp;	
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FitnessStrafingComp = UFitnessStrafingComponent::GetOrCreate(Owner);
	}

	private void Initialize()
	{
		if(Initialized)
			return;

		auto Weapon = UBasicAIWeaponWielderComponent::Get(Owner).Weapon;
		if(Weapon == nullptr)
			return;

		if(UEnforcerRifleComponent::Get(Weapon) != nullptr)
			RecoveryDuration = UEnforcerRifleSettings::GetSettings(Owner).RecoveryDuration;
		else if(UEnforcerRocketLauncherComponent::Get(Weapon) != nullptr)
			RecoveryDuration = UEnforcerRocketLauncherSettings::GetSettings(Owner).RecoveryDuration;
		else if(UEnforcerShotgunComponent::Get(Weapon) != nullptr)
			RecoveryDuration = UEnforcerShotgunSettings::GetSettings(Owner).RecoveryDuration;

		Initialized = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{		
		Super::OnActivated();
		Initialize();
		AnimComp.RequestOverrideFeature(LocomotionFeatureAISkylineTags::Enforcer_Recovery, this);

		UBasicAIProjectileLauncherComponentBase Weapon = UBasicAIProjectileLauncherComponentBase::Get(Owner);
		if (Weapon == nullptr)
		{
			UBasicAIWeaponWielderComponent WielderComp = UBasicAIWeaponWielderComponent::Get(Owner);
			if ((WielderComp != nullptr) && (WielderComp.Weapon != nullptr))
				Weapon = UBasicAIProjectileLauncherComponentBase::Get(WielderComp.Weapon);
		}

		UEnforcerWeaponEffectHandler::Trigger_OnReload(Weapon.LauncherActor, FEnforcerWeaponEffectReloadParams(RecoveryDuration));
		// UBasicAIWeaponEventHandler::Trigger_OnReload(Owner, FWeaponHandlingReloadParams(Weapon, RecoveryDuration));
		// UEnforcerEffectHandler::Trigger_OnReload(Owner, FEnforcerEffectOnReloadData(Weapon, RecoveryDuration));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > RecoveryDuration)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		FitnessStrafingComp.OptimizeStrafeDirection();
		UBasicAIWeaponEventHandler::Trigger_OnReloadComplete(Owner);
		UEnforcerEffectHandler::Trigger_OnReloadComplete(Owner);
	}
}