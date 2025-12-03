
class UGravityBladeArmorReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UGravityBladeCombatResponseComponent BladeResponse;
	UEnforcerArmorSettings ArmorSettings;
	UEnforcerArmorComponent ArmorComp;
	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ArmorComp = UEnforcerArmorComponent::Get(Owner);
		ArmorSettings = UEnforcerArmorSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		BladeResponse = UGravityBladeCombatResponseComponent::Get(Owner);		

		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(ArmorComp.bArmorEnabled)
			HealthComp.SetStunned();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!ArmorComp.bArmorEnabled)
			return false;
		if(!HealthComp.IsStunned())
			return false;
		if (Super::ShouldActivate() == false)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!ArmorComp.bArmorEnabled)
			return true;
		if(!HealthComp.IsStunned())
			return true;
		if (Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(n"EnforcerMinimalHitReaction", EBasicBehaviourPriority::High, this, ArmorSettings.ResistGravityBladeReactionDuration);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (ActiveDuration > ArmorSettings.ResistGravityBladeReactionDuration)
		{
			AnimComp.Reset();
			TargetComp.SetTarget(nullptr); // Select a new target
			HealthComp.ClearStunned();
			return;
		}

		Debug::DrawDebugArrow(Owner.FocusLocation, Owner.FocusLocation + Owner.ActorForwardVector * 1000.0);
	}
}