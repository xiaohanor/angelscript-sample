// This is basically a lambda, since the OnPlayerStartedPerchingEvent event doesn't send in the point index
// we instead bind this UObject and save the point index so we can access it.
class UTundra_SimonSaysPlayerDelegateData : UObject
{
	int PointIndex;
	UTundra_SimonSaysPlayerComponent PlayerComp;

	UFUNCTION()
	private void OnImpactTile(AHazePlayerCharacter Player)
	{
		PlayerComp.OnImpactTile(PointIndex);
	}
}

class UTundra_SimonSaysPlayerComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	ATundra_SimonSaysManager Manager;

	TArray<FTundra_SimonSaysTileData> PlayerTiles;
	TArray<UTundra_SimonSaysPlayerDelegateData> DelegateData;

	private bool bMeasureIsPerfect = true;
	bool bBeatIsDone = false;
	int CurrentPendingBeatIndex = -1;

	ACongaDanceFloorTile CurrentPerchedTile;
	ACongaDanceFloorTile CurrentPerchTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Manager = TundraSimonSays::GetManager();

		Manager.OnPlayerMeasureStart.AddUFunction(this, n"OnPlayerMeasureStart");
		Manager.OnPlayerEndedMeasure.AddUFunction(this, n"OnEndOfPlayerMeasure");
		Manager.OnNextStage.AddUFunction(this, n"OnNextStage");
	}

	UFUNCTION()
	private void OnNextStage(int NewStage)
	{
		for(int i = 0; i < PlayerTiles.Num(); i++)
		{
			ACongaDanceFloorTile Tile = PlayerTiles[i].Tile;
			Tile.OnPlayerImpactTile.Unbind(DelegateData[i], n"OnImpactTile");
		}

		PlayerTiles.Empty();
		DelegateData.Empty();

		Manager.GetTilesForPlayer(Player, PlayerTiles);

		for(int i = 0; i < PlayerTiles.Num(); i++)
		{
			ACongaDanceFloorTile Tile = PlayerTiles[i].Tile;
			auto Data = NewObject(this, UTundra_SimonSaysPlayerDelegateData);
			Data.PointIndex = i;
			Data.PlayerComp = this;

			Tile.OnPlayerImpactTile.AddUFunction(Data, n"OnImpactTile");
			DelegateData.Add(Data);
		}
	}

	UFUNCTION()
	private void OnPlayerMeasureStart()
	{
		bMeasureIsPerfect = true;
		CurrentPendingBeatIndex = 0;
	}

	void OnImpactTile(int PointIndex)
	{
		if(!Manager.IsActive())
			return;

		if(Manager.IgnoredTiles.Contains(PointIndex))
			return;

		int CorrectPointIndex = GetCorrectPointIndexFromBeatIndex(CurrentPendingBeatIndex);

		if(Manager.GetMainState() != ETundra_SimonSaysState::PlayerTurn && CorrectPointIndex != PointIndex)
		{
			if(Manager.GetMainState() == ETundra_SimonSaysState::PlayerToMonkeyPlayerStatus)
			{
				OnKillReaction(PointIndex);
			}
			return;
		}

		FTundra_SimonSaysSequence Sequence;
		Manager.GetCurrentDanceSequence(Sequence);

		if(CorrectPointIndex == PointIndex)
			OnCorrectPerchPoint(PointIndex);
		else
			OnIncorrectPerchPoint(PointIndex);

		if(Manager.GetMainState() == ETundra_SimonSaysState::PlayerTurn)
		{
			if(CurrentPendingBeatIndex >= Sequence.Sequence.Num() - 1)
			{
				CurrentPendingBeatIndex = -1;
				Manager.UpdateTileStatusForPlayer(Player);

				FTundra_SimonSaysManagerOnPlayerSuccessEffectParams Params;
				Params.Player = Player;
				if(HasSucceeded())
					UTundra_SimonSaysManagerEffectHandler::Trigger_OnPlayerSuccess(Manager, Params);
			}
			else
				++CurrentPendingBeatIndex;
		}
	}

	// Triggers when you land on the correct perch point.
	void OnCorrectPerchPoint(int PointIndex)
	{
		if(Manager.bDebug)
			Print("Correct perch point!", 5.f, FLinearColor::Green);

		bBeatIsDone = true;

		ACongaDanceFloorTile Tile = Manager.GetTileForPlayer(Player, PointIndex);
		FTundra_SimonSaysManagerTileGenericEffectParams Params;
		Params.Player = Player;
		Params.Tile = Tile;
		Params.TileType = TundraSimonSays::PointIndexToEffectTileType(PointIndex);
		Params.TileColor = Tile.CurrentColor;
		Params.TileTargetColor = Tile.InstigatedColor.Get();
		UTundra_SimonSaysManagerEffectHandler::Trigger_OnSuccessfulLand(Manager, Params);
	}

	// Triggers when you land on the incorrect perch point.
	void OnIncorrectPerchPoint(int PointIndex)
	{
		if(Manager.bDebug)
			Print("Incorrect perch point!", 5.f, FLinearColor::Red);

		bMeasureIsPerfect = false;
		Manager.UpdateTileStatusForPlayer(Player);
		bBeatIsDone = true;

		OnKillReaction(PointIndex);
	}

	void OnKillReaction(int PointIndex)
	{
		ACongaDanceFloorTile Tile = Manager.GetTileForPlayer(Player, PointIndex);

		FTundra_SimonSaysManagerTileGenericEffectParams Params;
		Params.Player = Player;
		Params.Tile = Tile;
		Params.TileType = TundraSimonSays::PointIndexToEffectTileType(PointIndex);
		Params.TileColor = Tile.CurrentColor;
		Params.TileTargetColor = Tile.InstigatedColor.Get();
		UTundra_SimonSaysManagerEffectHandler::Trigger_OnFailLand(Manager, Params);

		if(!HasControl())
			return;

		Manager.CrumbAddKillReactionTile(Tile, Player);
	}

	UFUNCTION()
	private void OnEndOfPlayerMeasure(AHazePlayerCharacter InPlayer, bool bSuccessful)
	{
		if(InPlayer != Player)
			return;

		if(Manager.bDebug)
		{
			if(bSuccessful)
				Print("Perfect measure", 5.f, FLinearColor::Green);
			else
				Print("Not perfect measure", 5.f, FLinearColor::Red);
		}
	}

	int GetCorrectPointIndexFromBeatIndex(int BeatIndex)
	{
		FTundra_SimonSaysSequence Sequence;
		Manager.GetCurrentDanceSequence(Sequence);

		if(BeatIndex < 0 || BeatIndex >= Sequence.Sequence.Num())
			return -1;

		return Sequence.Sequence[BeatIndex];
	}

	FQuat GetTargetPlayerRotation() const
	{
		FVector PlayerToTarget = (CurrentPerchTarget.SimonSaysTargetable.WorldLocation - Player.ActorLocation).GetSafeNormal2D();
		return PlayerToTarget.ToOrientationQuat();
	}

	bool HasSucceeded()
	{
		if(Player.IsZoe() && Tundra_SimonSaysDevToggles::SimonSaysIgnoreZoePerformance.IsEnabled())
			return true;

		return bMeasureIsPerfect && CurrentPendingBeatIndex == -1;
	}

	bool HasFailed()
	{
		if(Player.IsZoe() && Tundra_SimonSaysDevToggles::SimonSaysIgnoreZoePerformance.IsEnabled())
			return false;

		return !bMeasureIsPerfect;
	}
}