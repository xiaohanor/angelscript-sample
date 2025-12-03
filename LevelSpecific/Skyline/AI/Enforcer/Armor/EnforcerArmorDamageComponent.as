class UEnforcerArmorDamageComponent : UEnforcerDamageComponent
{
	UEnforcerArmorComponent ArmorComp;
	UEnforcerArmorSettings ArmorSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ArmorComp = UEnforcerArmorComponent::Get(Owner);
		ArmorSettings = UEnforcerArmorSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	protected void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData) override
	{			
		if(ArmorComp.bArmorEnabled)
		{			
			FVector Direction = (CombatComp.Owner.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			CombatComp.TriggerRecoil(Direction, ArmorSettings.ResistGravityBladeReactionDuration);
			return;
		}
		
		UEnforcerDamageComponent::OnBladeHit(CombatComp, HitData);
	}
}