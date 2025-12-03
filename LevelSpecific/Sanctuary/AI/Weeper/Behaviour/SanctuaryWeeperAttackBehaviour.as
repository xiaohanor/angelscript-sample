
class USanctuaryWeeperAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	float AttackDuration = 0.5;
	USanctuaryWeeperSettings WeeperSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WeeperSettings = USanctuaryWeeperSettings::GetSettings(Owner);
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
			HealthComp.KillPlayer(FPlayerDeathDamageParams(), nullptr);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(SanctuaryWeeperTags::Attack, EBasicBehaviourPriority::Medium, this, AttackDuration);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveTowards(TargetComp.Target.ActorLocation, 1000.0);
	}
}