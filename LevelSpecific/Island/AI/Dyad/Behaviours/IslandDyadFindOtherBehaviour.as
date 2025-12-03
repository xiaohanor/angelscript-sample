
// Move towards enemy
class UIslandDyadFindOtherBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandDyadSettings DyadSettings;
	UIslandDyadLaserComponent LaserComp;
	UIslandForceFieldComponent ForceFieldComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DyadSettings = UIslandDyadSettings::GetSettings(Owner);
		LaserComp = UIslandDyadLaserComponent::GetOrCreate(Owner);
		ForceFieldComp = UIslandForceFieldComponent::Get(Owner);

		UBasicAIHealthComponent::Get(Owner).OnDie.AddUFunction(this, n"OnDie");
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		if(LaserComp.OtherDyad != nullptr)
			UIslandDyadLaserComponent::GetOrCreate(LaserComp.OtherDyad).OtherDyad = nullptr;
		LaserComp.OtherDyad = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!LaserComp.bCanConnect)
			return false;
		if (LaserComp.OtherDyad != nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(!LaserComp.bCanConnect)
			return true;
		if (LaserComp.OtherDyad != nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UHazeTeam Team = HazeTeam::GetTeam(IslandDyadTags::IslandDyadTeam);
		if(Team == nullptr)
			return;

		for(AHazeActor Member: Team.GetMembers())
		{
			if(Member == Owner)
				continue;

			UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Member);
			if(HealthComp.IsDead())
				continue;

			UIslandDyadLaserComponent OtherLaserComp = UIslandDyadLaserComponent::GetOrCreate(Member);

			if(OtherLaserComp.OtherDyad != nullptr)
				continue;

			if(!OtherLaserComp.bCanConnect)
				continue;

			UIslandForceFieldComponent OtherForceFieldComp = UIslandForceFieldComponent::Get(Member);
			if(OtherForceFieldComp.CurrentType != ForceFieldComp.CurrentType)
			{
				LaserComp.OtherDyad = Cast<AAIIslandDyad>(Member);
				LaserComp.bPrimaryDyad = true;
				OtherLaserComp.OtherDyad = Cast<AAIIslandDyad>(Owner);
				OtherLaserComp.bPrimaryDyad = false;
				break;
			}
		}
	}
}