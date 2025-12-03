class USummitCrystalSkullBossForceFieldComponent : UStaticMeshComponent
{
	USummitCrystalSkullsTeam Team;

	void Initialize(USummitCrystalSkullsTeam SkullsTeam)
	{
		Team = SkullsTeam;
	}

	bool IsOperational() const
	{
		if ((Team.LeftWing == nullptr) || (Team.RightWing== nullptr))	
			return false;		

		UBasicAIHealthComponent RightHealthComp = UBasicAIHealthComponent::Get(Team.RightWing);
		if (RightHealthComp.IsAlive())
			return true;
		UBasicAIHealthComponent LeftHealthComp = UBasicAIHealthComponent::Get(Team.LeftWing);
		if (LeftHealthComp.IsAlive())
			return true;
		return false;
	}
}
