class ASkylineEnforcerForceField : AHazeActor
{
	AHazeActor HazeOwner;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponse;

	UPROPERTY(DefaultComponent)
	UGravityWhipImpactResponseComponent WhipResponse;

	USkylineEnforcerForceFieldComponent ForceFieldComp;
	UEnforcerForceFieldSettings ForceFieldSettings;
	bool bEnabled = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceFieldComp = USkylineEnforcerForceFieldComponent::Get(HazeOwner);

		ForceFieldSettings = UEnforcerForceFieldSettings::GetSettings(this);
		WhipResponse.OnImpact.AddUFunction(this, n"OnImpact");
		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");		
	}

	UFUNCTION()
	protected void OnImpact(FGravityWhipImpactData ImpactData)
	{
		if(!bEnabled)
			return;

		ForceFieldComp.Break();
	}

	UFUNCTION()
	protected void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{			
		if(!bEnabled)
			return;

		FVector Direction = (CombatComp.Owner.ActorLocation - ActorLocation).GetSafeNormal();
		CombatComp.TriggerRecoil(Direction, ForceFieldSettings.ResistGravityBladeReactionDuration);
		auto Data = FEnforcerEffectOnShieldDeflectData();
		Data.ImpactWorldLocation = ActorLocation + Direction * 100.0;
	}
}