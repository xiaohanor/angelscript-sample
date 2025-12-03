
class UIslandNecromancerReviveBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UBasicAIHealthComponent HealthComp;
	UBasicAIMeleeWeaponComponent Weapon;
	float Duration = 0.75;
	UIslandZombieSettings ZombieSettings;

	UIslandNecromancerReviveTargetComponent Target;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Weapon = UBasicAIMeleeWeaponComponent::Get(Owner);
		ZombieSettings = UIslandZombieSettings::GetSettings(Owner);
		devCheck(Weapon != nullptr, "" + Owner.Name + " has a melee attack capability but no weapon! Give them a BasicAIMeleeComponent.");
	}

	bool GetRevivableTarget(FIslandNecromancerReviveParams& Params) const
	{
		auto Team = HazeTeam::GetTeam(IslandNecromancerTags::IslandNecromancerReviveTargetTeam);
		if(Team == nullptr)
			return false;

		for(AHazeActor Member: Team.GetMembers())
		{
			if (Member == nullptr)
				continue;
			auto ReviveComp = UIslandNecromancerReviveTargetComponent::Get(Member);
			if(ReviveComp != nullptr && ReviveComp.bEnabled && ReviveComp.IsRevivable())
			{
				Params.Target = ReviveComp;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandNecromancerReviveParams& Params) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!GetRevivableTarget(Params))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandNecromancerReviveParams Params)
	{
		Super::OnActivated();
		Target = Params.Target;

		// Start melee attack (note that we do not need to request this continuously, ABP stays active as long as needed)
		AnimComp.RequestFeature(LocomotionFeatureAITags::MeleeCombat, SubTagAIMeleeCombat::HeavyAttack, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration > Duration)
		{
			Target.Revive();
			DeactivateBehaviour();
		}		
	}
}

struct FIslandNecromancerReviveParams
{
	UIslandNecromancerReviveTargetComponent Target;
}