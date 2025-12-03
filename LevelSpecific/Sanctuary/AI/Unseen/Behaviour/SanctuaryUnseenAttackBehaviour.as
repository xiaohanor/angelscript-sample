
class USanctuaryUnseenAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	float AttackDuration = 0.3;
	USanctuaryUnseenSettings UnseenSettings;
	USanctuaryUnseenChaseComponent ChaseComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		UnseenSettings = USanctuaryUnseenSettings::GetSettings(Owner);
		ChaseComp = USanctuaryUnseenChaseComponent::Get(Owner);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.AttackRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!WantsToAttack())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > AttackDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(TargetComp.Target);
		if(HealthComp != nullptr)
			HealthComp.DamagePlayer(0.33, nullptr, nullptr);

		Cooldown.Set(BasicSettings.AttackCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveTowards(TargetComp.Target.ActorLocation, 1000.0);
	}
}