UFUNCTION()
mixin void SetAggroTargetForSpawn(AHazeActorSpawnerBase Spawner, AHazeActor Target, int AggressionBonus = 0)
{
	if ((Spawner == nullptr) || (Spawner.SpawnerComp == nullptr) || (Spawner.SpawnerComp.SpawnedActorsTeam == nullptr))
		return;

	for (AHazeActor Spawn : Spawner.SpawnerComp.SpawnedActorsTeam.GetMembers())
	{
		if ((Spawn == nullptr) || Spawn.IsActorDisabled())
			continue;

		// Note that this will set the aggro target, but AI also needs some behaviour to handle switching target
		UBasicAITargetingComponent TargetComp = UBasicAITargetingComponent::Get(Spawn);
		TargetComp.SetAggroTarget(Target);
	}

	if (AggressionBonus > 0)
	{
		UGentlemanCostSettings Settings = UGentlemanCostSettings::GetSettings(Target);
		UGentlemanCostSettings::SetMaxAggressionLevel(Target, Settings.MaxAggressionLevel + AggressionBonus, Spawner, EHazeSettingsPriority::Script);
	} 
}

UFUNCTION()
mixin void ClearAggroTargetForSpawn(AHazeActorSpawnerBase Spawner, AHazeActor Target)
{
	if ((Spawner == nullptr) || (Spawner.SpawnerComp == nullptr) || (Spawner.SpawnerComp.SpawnedActorsTeam == nullptr))
		return;

	for (AHazeActor Spawn : Spawner.SpawnerComp.SpawnedActorsTeam.GetMembers())
	{
		if (Spawn == nullptr)
			continue;

		UBasicAITargetingComponent TargetComp = UBasicAITargetingComponent::Get(Spawn);
		TargetComp.SetAggroTarget(nullptr);
	}

	UGentlemanCostSettings::ClearMaxAggressionLevel(Target, Spawner);
}
