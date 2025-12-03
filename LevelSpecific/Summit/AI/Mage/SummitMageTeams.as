class USummitMagePlateTeam : UHazeTeam
{
	UFUNCTION()
	void SetMeleeMode()
	{
		TArray<AHazeActor> CurrentMembers = GetMembers();
		for(auto Member: CurrentMembers)
		{
			if (Member == nullptr)
				continue;
			USummitMageModeComponent ModeComp = USummitMageModeComponent::Get(Member);
			ModeComp.Mode = ESummitMageMode::Melee;
		}
	}
}

class USummitMagePlateUserTeam : UHazeTeam
{
	UFUNCTION()
	void Expire()
	{
		TArray<AHazeActor> CurrentMembers = GetMembers();
		for(auto Member: CurrentMembers)
		{
			if (Member == nullptr)
				continue;
			UBasicAIProjectileComponent ProjComp = UBasicAIProjectileComponent::Get(Member);
			ProjComp.Expire();
		}
	}
}