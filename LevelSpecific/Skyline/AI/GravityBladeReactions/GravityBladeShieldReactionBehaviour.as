
class UGravityBladeShieldReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UGravityBladeCombatResponseComponent BladeResponse;
	UEnforcerShieldSettings ShieldSettings;
	UEnforcerShieldComponent ShieldComp;
	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ShieldComp = UEnforcerShieldComponent::Get(Owner);
		ShieldSettings = UEnforcerShieldSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		BladeResponse = UGravityBladeCombatResponseComponent::Get(Owner);		

		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(ShieldComp.bEnabled)
			HealthComp.SetStunned();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!ShieldComp.bEnabled)
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
		if(!ShieldComp.bEnabled)
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
		AnimComp.RequestFeature(n"EnforcerMinimalHitReaction", EBasicBehaviourPriority::High, this, ShieldSettings.ResistGravityBladeReactionDuration);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (ActiveDuration > ShieldSettings.ResistGravityBladeReactionDuration)
		{
			AnimComp.Reset();
			TargetComp.SetTarget(nullptr); // Select a new target
			HealthComp.ClearStunned();
			return;
		}

		Debug::DrawDebugArrow(Owner.FocusLocation, Owner.FocusLocation + Owner.ActorForwardVector * 1000.0);
	}
}