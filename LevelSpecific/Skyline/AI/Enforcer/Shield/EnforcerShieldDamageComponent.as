class UEnforcerShieldDamageComponent : UEnforcerDamageComponent
{
	UEnforcerShieldComponent ShieldComp;
	UEnforcerShieldSettings ShieldSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ShieldComp = UEnforcerShieldComponent::Get(Owner);
		ShieldSettings = UEnforcerShieldSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	protected void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData) override
	{			
		if(ShieldComp.bEnabled)
		{
			FVector Direction = (CombatComp.Owner.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			CombatComp.TriggerRecoil(Direction, ShieldSettings.ResistGravityBladeReactionDuration);
			auto Data = FEnforcerEffectOnShieldDeflectData();
			Data.ImpactWorldLocation = ShieldComp.WorldLocation + Direction * 100.0;
			return;
		}
		
		UEnforcerDamageComponent::OnBladeHit(CombatComp, HitData);
	}
}