class USkylineEnforcerForceFieldDamageComponent : UEnforcerDamageComponent
{
	USkylineEnforcerForceFieldComponent ForceFieldComp;
	UEnforcerForceFieldSettings ForceFieldSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ForceFieldComp = USkylineEnforcerForceFieldComponent::Get(Owner);
		ForceFieldSettings = UEnforcerForceFieldSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	protected void OnImpact(FGravityWhipImpactData ImpactData) override
	{
		if(ForceFieldComp.ForceField.bEnabled)
			return;
		HealthComp.TakeDamage(BIG_NUMBER, EDamageType::Default, nullptr);
	}

	protected void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData) override
	{			
		if(ForceFieldComp.ForceField.bEnabled)
			return;
		UEnforcerDamageComponent::OnBladeHit(CombatComp, HitData);
	}
}