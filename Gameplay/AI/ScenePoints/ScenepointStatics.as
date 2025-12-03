namespace Scenepoint
{
	UScenepointComponent GetEntryScenePoint(UScenepointUserComponent ScenepointUserComp, UHazeActorRespawnableComponent RespawnComp)
	{
		// If we've been assigned a scenepoint when spawned, we use that
		if ((RespawnComp != nullptr) && (RespawnComp.SpawnParameters.Scenepoint != nullptr))
			return RespawnComp.SpawnParameters.Scenepoint;

		// Fall back to any scene point user entry point
		if ((ScenepointUserComp != nullptr) && (ScenepointUserComp.EntryScenepoint != nullptr))
			return ScenepointUserComp.EntryScenepoint.GetScenepoint();

		return nullptr;
	}
}
