
class USkylineTurretDamageReactionBehaviour : UBasicBehaviour
{
    UGravityBladeCombatResponseComponent BladeResponseComp;
	UBasicAIHealthComponent HealthComp;
	USkylineTurretSettings Settings;
		
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineTurretSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		BladeResponseComp = UGravityBladeCombatResponseComponent::Get(Owner);
		BladeResponseComp.OnHit.AddUFunction(this, n"OnBladeHit");		
		HealthComp.OnDie.AddUFunction(this, n"OnDie");
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		USkylineTurretEffectHandler::Trigger_OnDeath(Owner);
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		USkylineTurretEffectHandler::Trigger_OnDamage(Owner, FSkylineTurretBladeHitImpactParams(HitData.ImpactPoint));
        HealthComp.TakeDamage(Settings.GravityBladeDamage, HitData.DamageType, Cast<AHazeActor>(CombatComp.Owner));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Time::GetGameTimeSince(HealthComp.LastDamageTime) > 0.5)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.HurtReactionDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
        // Will probably not have an animation
		// AnimComp.RequestFeature(LocomotionFeatureAITags::HurtReactions, SubTagAIHurtReactions::Default, EBasicBehaviourPriority::Medium, this, Settings.HurtReactionDuration);
	}
}

