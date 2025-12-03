class USummitShardSpawnerActivateMetalSpawnerBehaviour : UBasicBehaviour
{
	bool FindMetalSpawners(FSummitShardSpawnerActivateMetalSpawnerActivationParams& Params) const
	{
		UHazeTeam Team = HazeTeam::GetTeam(SummitSpawnerTags::MetalSpawnerTeam);
		TArray<AHazeActor> Members = Team.GetMembers();
		for(AHazeActor Member: Members)
		{
			if (Member == nullptr)
				continue;
			ASummitMetalSpawner MetalSpawner = Cast<ASummitMetalSpawner>(Member);
			if(MetalSpawner == nullptr) continue;
			Params.Spawner = MetalSpawner;
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitShardSpawnerActivateMetalSpawnerActivationParams& Params) const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!FindMetalSpawners(Params))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitShardSpawnerActivateMetalSpawnerActivationParams Params)
	{
		Super::OnActivated();
	}
}

struct FSummitShardSpawnerActivateMetalSpawnerActivationParams
{
	ASummitMetalSpawner Spawner;
}
