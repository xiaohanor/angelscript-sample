
class UIslandBigZombieAttackBehaviour : UBasicBehaviour
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
	TArray<UIslandBigZombieAttackResponseComponent> PerformedImpacts;

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
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		// Start melee attack (note that we do not need to request this continuously, ABP stays active as long as needed)
		AnimComp.RequestFeature(LocomotionFeatureAITags::MeleeCombat, SubTagAIMeleeCombat::FinisherAttack, EBasicBehaviourPriority::Medium, this);
		PerformedImpacts.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnimComp.RequestFeature(LocomotionFeatureAITags::MeleeCombat, SubTagAIMeleeCombat::FinisherAttack, EBasicBehaviourPriority::Medium, this);

		if(ActiveDuration < 1.0 || ActiveDuration > 1.5) return;
		PrintToScreen("KILLING");
		auto Team = HazeTeam::GetTeam(n"BigZombieAttackTarget");
		for(AHazeActor Member: Team.GetMembers())
		{
			auto ResponseComp = (Member != nullptr) ? UIslandBigZombieAttackResponseComponent::Get(Member) : nullptr;
			if(ResponseComp == nullptr) 
				continue;
			if(CanHit(ResponseComp))
				Hit(ResponseComp);
		}
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
	}

	bool CanHit(UIslandBigZombieAttackResponseComponent Comp)
	{
		if(PerformedImpacts.Contains(Comp))
			return false;

		if(Weapon.WorldLocation.IsWithinDist(Comp.WorldLocation, 200.0))
		{
			return true;
		}		

		return false;
	}

	void Hit(UIslandBigZombieAttackResponseComponent Comp)
	{
		PerformedImpacts.Add(Comp);
		auto Character = Cast<AHazeCharacter>(Owner);
		if(Character == nullptr) return;
		Comp.OnImpact.Broadcast(Character);
	}
}

