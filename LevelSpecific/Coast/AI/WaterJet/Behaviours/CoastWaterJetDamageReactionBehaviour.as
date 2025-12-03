class UCoastWaterJetDamageReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UCoastWaterJetSettings Settings;
	UCoastShoulderTurretGunResponseComponent ResponseComp;
	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastWaterJetSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);		
		ResponseComp = UCoastShoulderTurretGunResponseComponent::GetOrCreate(Owner);
		ResponseComp.OnBulletHit.AddUFunction(this, n"OnHit");
	}

	UFUNCTION()
	private void OnHit(FCoastShoulderTurretBulletHitParams Params)
	{
		HealthComp.TakeDamage(Params.Damage * Settings.DamageFromProjectilesFactor, EDamageType::Projectile, Params.PlayerInstigator);
		UCoastWaterJetEffectHandler::Trigger_OnTakeDamage(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Time::GetGameTimeSince(HealthComp.LastDamageTime) > Settings.DamageReactionDuration * 0.5)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.DamageReactionDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(LocomotionFeatureAITags::HurtReactions, SubTagAIHurtReactions::Default, EBasicBehaviourPriority::Medium, this, Settings.DamageReactionDuration);
	}
}
