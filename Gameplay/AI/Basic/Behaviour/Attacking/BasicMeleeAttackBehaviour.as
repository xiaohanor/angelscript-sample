
class UBasicMeleeAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UBasicAIMeleeWeaponComponent Weapon;
	FName Attack = SubTagAIMeleeCombat::SingleAttack;
	float AttackDuration = 2.0;
	float AttackChance = 0.0;

	UBasicMeleeAttackBehaviour(FName AttackSubTag, float Duration, float Chance)
	{
		Attack = AttackSubTag;
		AttackDuration = Duration;
		AttackChance = Chance;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Weapon = UBasicAIMeleeWeaponComponent::Get(Owner);
		devCheck(Weapon != nullptr, "" + Owner.Name + " has a melee attack capability but no weapon! Give them a BasicAIMeleeComponent.");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!Weapon.Cooldown.IsOver())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (Math::RandRange(0.001, 1.0) > AttackChance)
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.AttackRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		// Start melee attack (note that we do not need to request this continuously, ABP stays active as long as needed)
		AnimComp.RequestFeature(LocomotionFeatureAITags::MeleeCombat, Attack, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > AttackDuration)
		{
			Cooldown.Set(BasicSettings.AttackCooldown);
			Weapon.Cooldown.Set(BasicSettings.AttackCooldown);
		}
	}
}

