
class UIslandZombieAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	UBasicAIMeleeWeaponComponent Weapon;
	float AttackDuration = 2.0;
	UIslandZombieSettings ZombieSettings;
	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Weapon = UBasicAIMeleeWeaponComponent::Get(Owner);
		ZombieSettings = UIslandZombieSettings::GetSettings(Owner);
		devCheck(Weapon != nullptr, "" + Owner.Name + " has a melee attack capability but no weapon! Give them a BasicAIMeleeComponent.");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!Weapon.Cooldown.IsOver())
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
		if(!GentCostQueueComp.IsNext(this))
			return false;
		if(!GentCostComp.IsTokenAvailable(ZombieSettings.AttackGentlemanCost))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, ZombieSettings.AttackGentlemanCost);
		// Start melee attack (note that we do not need to request this continuously, ABP stays active as long as needed)
		AnimComp.RequestFeature(LocomotionFeatureAITags::MeleeCombat, SubTagAIMeleeCombat::HeavyAttack, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnimComp.RequestFeature(LocomotionFeatureAITags::MeleeCombat, SubTagAIMeleeCombat::HeavyAttack, EBasicBehaviourPriority::Medium, this);
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
		Cooldown.Set(BasicSettings.AttackCooldown);
		Weapon.Cooldown.Set(BasicSettings.AttackCooldown);
		GentCostComp.ReleaseToken(this, ZombieSettings.AttackTokenCooldown);
	}
}

