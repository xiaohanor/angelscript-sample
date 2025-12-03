namespace SkylineHighwayCombatStatics
{
	UFUNCTION()
	void RemoveAllHighwayCombatEnforcers(FInstigator Instigator)
	{
		UHazeTeam Team = HazeTeam::GetTeam(n"BasicAITeam");
		if(Team != nullptr)
		{
			TArray<AHazeActor> Members = Team.GetMembers();
			for(AHazeActor Member : Members)
			{
				AAISkylineEnforcerBase Enforcer = Cast<AAISkylineEnforcerBase>(Member);
				if(Enforcer == nullptr)
					continue;
				Enforcer.AddActorDisable(Instigator);
			}
		}
		
		TArray<AEnforcerGrenade> Grenades =	TListedActors<AEnforcerGrenade>().Array;
		for (AEnforcerGrenade Grenade : Grenades)
		{
			if(Grenade == nullptr)
				continue;
			Grenade.AddActorDisable(Instigator);
		}
	}
}