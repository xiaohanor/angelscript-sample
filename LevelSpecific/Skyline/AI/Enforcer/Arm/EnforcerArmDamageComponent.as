class UEnforcerArmDamageComponent : UEnforcerDamageComponent
{
	UEnforcerArmComponent ArmComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ArmComp = UEnforcerArmComponent::Get(Owner);
	}

	protected void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData) override
	{			
		if(!ArmComp.bStruggling)
			return;

		UEnforcerDamageComponent::OnBladeHit(CombatComp, HitData);
	}
}