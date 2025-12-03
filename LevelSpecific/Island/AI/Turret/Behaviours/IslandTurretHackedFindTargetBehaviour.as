class UIslandTurretHackedFindTargetBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UBasicAIHealthComponent HealthComp;
	UIslandTurretHackComponent HackComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HackComp = UIslandTurretHackComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(HackComp.IsHacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UHazeTeam Team = HazeTeam::GetTeam(n"BasicAITeam");

		for(AHazeActor Member: Team.GetMembers())
		{
			if (Member != nullptr && Member != Owner && Member.ActorLocation.IsWithinDist(Owner.ActorLocation, BasicSettings.AttackRange))
			{
				TargetComp.SetTarget(Member);
				return;
			}	
		}
	}
}
