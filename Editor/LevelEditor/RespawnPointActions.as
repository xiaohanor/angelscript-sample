class URespawnPointActions : UScriptActorMenuExtension
{
	default ExtensionPoint = n"ActorPreview";
	default ExtensionOrder = EScriptEditorMenuExtensionOrder::After;
	default SupportedClasses.Add(ARespawnPoint);

	/** Start playing at the selected respawn point. */
	UFUNCTION(CallInEditor, Meta = (EditorIcon = "PlayWorld.PlayInViewport"))
	void PlayFromRespawnPoint()
	{
		ARespawnPoint RespawnPoint;
		auto Selection = Editor::GetSelectedActors();

		for (auto Actor : Selection)
		{
			RespawnPoint = Cast<ARespawnPoint>(Actor);
			if (RespawnPoint != nullptr)
				break;
		}

		if (RespawnPoint == nullptr)
			return;

		auto Starter = URespawnPointActivatorStarter();
		Starter.LevelName = RespawnPoint.Level.Outer.Name;
		Starter.RespawnPointName = RespawnPoint.Name;
		Starter.AddToRoot();

		Editor::StartPlayFromHere(
			RespawnPoint.GetStoredSpawnPosition(EHazePlayer::Mio),
			RespawnPoint.GetStoredSpawnPosition(EHazePlayer::Zoe),
		);
	}
}

class URespawnPointActivatorStarter : UObjectTickable
{
	FName LevelName;
	FName RespawnPointName;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		{
			FScopeDebugPrimaryWorld ScopeWorld;
			MarkRespawnPointActive();
		}

		{
			FScopeDebugSecondaryWorld ScopeWorld;
			MarkRespawnPointActive();
		}

		RemoveFromRoot();
		DestroyObject();
	}

	void MarkRespawnPointActive()
	{
		TListedActors<ARespawnPoint> RespawnPoints;
		for (auto RespawnPoint : RespawnPoints)
		{
			if (RespawnPoint.Name != RespawnPointName)
				continue;
			if (RespawnPoint.Level.Outer.Name != LevelName)
				continue;

			for (auto Player : Game::Players)
				Player.SetStickyRespawnPoint(RespawnPoint);
			break;
		}
	}
}