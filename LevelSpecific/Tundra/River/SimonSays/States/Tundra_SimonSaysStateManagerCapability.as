class UTundra_SimonSaysStateManagerComponent : UActorComponent
{
	FHazeStructQueue StateQueue;
}

class UTundra_SimonSaysStateManagerCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Input;

	ATundra_SimonSaysManager Manager;
	UTundra_SimonSaysStateManagerComponent StateComp;

	bool bDoPreStage = false;
	bool bInitialStage = true;

	FTundra_SimonSaysStateDanceFloorWaveData WaveData;
	default WaveData.TileWaveDuration = 0.5;
	default WaveData.TileRowActivateOffset = 0.1;
	default WaveData.TileWaveMaxHeight = 100.0;
	//default WaveData.OverrideColor(FLinearColor::Green);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = TundraSimonSays::GetManager();
		StateComp = UTundra_SimonSaysStateManagerComponent::GetOrCreate(Manager);
		Manager.OnNextStage.AddUFunction(this, n"OnNextStage");
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
#if !RELEASE
		TemporalLog
			.Value("Current Main State", Manager.GetMainState())
			.Value("Current Secondary State", Manager.GetSecondaryState())
			.Value("Queue Length", StateComp.StateQueue.Num())
			.Value("Queue", StateComp.StateQueue)
			.Value("Active Duration", Manager.GetActiveDuration())
			.Value("Completed States Active Duration", Manager.CompletedStatesTotalDuration)
			.Value("Current State Active Duration", Manager.GetCurrentStateActiveDuration())
		;
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(!Manager.IsActive())
			return false;

		if(!StateComp.StateQueue.IsEmpty())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(Manager.bDeactivatePending)
		{
			Delay(0, n"Pre Success Delay");
			PlayerToMonkeyCamera(2);
			MonkeySuccess(2);
			MoveDownMonkeyKingPlatforms(1);
			Delay(1, n"Pre Deactivate Delay");
			DeactivateSimonSays();
			SnapDownMiddlePlatform();
			SnapDownOuterPlatforms();
			return;
		}
		else if(ConsumeInitialStage())
		{
			MoveUpMiddlePlatform(2, Manager.bShouldSnapPlatformsOnActivated);
			Delay(4, n"First Stage Initial Delay");
		}
		else if(ConsumePreStage())
		{
			Delay(1, n"Pre Success Delay");
			PlayerToMonkeyCamera(2, -1);
			SnapDownOldOuterPlatforms();
			MonkeySuccess(2);
			DanceFloorWave(WaveData);
			MonkeyToPlayerCamera(2);
			MoveUpMiddlePlatform(1);
			WaitForPlayersToJumpToNextStage();
			MoveDownOldMiddlePlatform(2);
			Delay(1, n"Pre Stage Additional Delay");
			PlayerToMonkeyCamera(2);
		}
		else
		{
			MoveDownOuterPlatforms(1);
			PlayerToMonkeyCamera(2);
		}

		Delay(2, n"Player To Monkey Additional Delay");
		MonkeyTurn(1);
		Delay(0, n"Pre Monkey To Player Delay");
		MonkeyToPlayerCamera(2);
		MoveUpOuterPlatforms(1);
		PlayerTurn(3.0);
		PlayerToMonkeyPlayerStatus(1);
	}

	UFUNCTION()
	private void OnNextStage(int NewStageIndex)
	{
		bDoPreStage = true;
	}

	/* Will return true only once */
	bool ConsumeInitialStage()
	{
		bool bWasTrue = bInitialStage;
		bInitialStage = false;
		if(bWasTrue)
			bDoPreStage = false;
		return bWasTrue;
	}

	/* Will return true once per every new stage */
	bool ConsumePreStage()
	{
		bool bWasTrue = bDoPreStage;
		bDoPreStage = false;
		return bWasTrue;
	}

	void DanceFloorWave(FTundra_SimonSaysStateDanceFloorWaveData Data)
	{
		StateComp.StateQueue.Queue(Data);
	}

	void MonkeySuccess(int BeatDuration, bool bShouldDeactivateSimonSays = false)
	{
		FTundra_SimonSaysStateMonkeySuccessAnimationData Data;
		Data.BeatDuration = BeatDuration;
		Data.bShouldDeactivateSimonSays = bShouldDeactivateSimonSays;
		StateComp.StateQueue.Queue(Data);
	}

	void PlayerToMonkeyCamera(int BeatDuration, int StageOffset = 0)
	{
		FTundra_SimonSaysStatePlayerToMonkeyCameraData Data;
		Data.BeatDuration = BeatDuration;
		Data.StageToSetLocationTo = Manager.GetCurrentDanceStageIndex() + StageOffset;

		StateComp.StateQueue.Queue(Data);
	}

	void MonkeyToPlayerCamera(int BeatDuration)
	{
		FTundra_SimonSaysStateMonkeyToPlayerCameraData Data;
		Data.BeatDuration = BeatDuration;
		StateComp.StateQueue.Queue(Data);
	}

	void MoveUpMiddlePlatform(int BeatDuration, bool bSnap = false)
	{
		MovePlatforms(ETundra_SimonSaysStateSelectedMovingTiles::Ignored, true, BeatDuration, Manager.GetCurrentDanceStageIndex(), Manager.TileMoveUpDistance, bSnap);
	}

	void WaitForPlayersToJumpToNextStage()
	{
		FTundra_SimonSaysStateWaitForPlayersToJumpToNextStageData Data;
		StateComp.StateQueue.Queue(Data);
	}

	void MoveDownOldMiddlePlatform(int BeatDuration)
	{
		int Stage = Manager.GetCurrentDanceStageIndex() - 1;
		if(Stage < 0)
			return;
		
		MovePlatforms(ETundra_SimonSaysStateSelectedMovingTiles::Ignored, false, BeatDuration, Stage, Manager.TileMoveUpDistance, false);
	}

	void SnapDownMiddlePlatform()
	{
		MovePlatforms(ETundra_SimonSaysStateSelectedMovingTiles::Ignored, false, 1, Manager.GetCurrentDanceStageIndex(), Manager.TileMoveUpDistance, true);
	}

	void SnapDownOuterPlatforms()
	{
		MovePlatforms(ETundra_SimonSaysStateSelectedMovingTiles::NonIgnored, false, 1, Manager.GetCurrentDanceStageIndex(), Manager.TileMoveUpDistance, true);
	}

	void SnapDownOldOuterPlatforms()
	{
		int Stage = Manager.GetCurrentDanceStageIndex() - 1;
		if(Stage < 0)
			return;

		MovePlatforms(ETundra_SimonSaysStateSelectedMovingTiles::NonIgnored, false, 1, Stage, Manager.TileMoveUpDistance, true);
	}

	void MoveDownOuterPlatforms(int BeatDuration)
	{
		MovePlatforms(ETundra_SimonSaysStateSelectedMovingTiles::NonIgnored, false, BeatDuration, Manager.GetCurrentDanceStageIndex(), Manager.TileMoveUpDistance, false);
	}

	void MoveUpOuterPlatforms(int BeatDuration)
	{
		MovePlatforms(ETundra_SimonSaysStateSelectedMovingTiles::NonIgnored, true, BeatDuration, Manager.GetCurrentDanceStageIndex(), Manager.TileMoveUpDistance, false);
	}

	void MoveDownMonkeyKingPlatforms(int BeatDuration, bool bShouldDeactivateSimonSays = false)
	{
		FTundra_SimonSaysStateMonkeyKingTileMoveData Data;
		Data.MoveDistance = 313.778419;
		Data.MoveDurationInBeats = BeatDuration;
		Data.bMoveUp = false;
		Data.bShouldDeactivateSimonSays = bShouldDeactivateSimonSays;
		StateComp.StateQueue.Queue(Data);
	}

	void MovePlatforms(ETundra_SimonSaysStateSelectedMovingTiles TilesSelector, bool bMoveUp, int MoveDurationInBeats, int Stage, float MoveDistance, bool bSnap)
	{
		FTundra_SimonSaysStateTileMoveData Data;
		Data.TilesSelector = TilesSelector;
		Data.bMoveUp = bMoveUp;
		Data.MoveDurationInBeats = MoveDurationInBeats;
		Data.Stage = Stage;
		Data.MoveDistance = MoveDistance;
		Data.bSnap = bSnap;
		StateComp.StateQueue.Queue(Data);
	}

	// Adds a monkey light up tile state capability for each beat in the sequence
	// void MonkeyTurn(int BeatDurationPerMove)
	// {
	// 	FTundra_SimonSaysStage Stage;
	// 	Manager.GetCurrentDanceStage(Stage);
	// 	int SequenceIndex = Manager.GetCurrentDanceSequenceIndex();
	// 	TArray<int> Sequence = Stage.Sequences[SequenceIndex].Sequence;

	// 	for(int MoveIndex = 0; MoveIndex < Sequence.Num(); MoveIndex++)
	// 	{
	// 		MonkeyLightUpTile(BeatDurationPerMove, Sequence[MoveIndex], MoveIndex == Sequence.Num() - 1);
	// 	}
	// }

	// Adds a monkey king move capability for each beat in sequence
	void MonkeyTurn(int BeatDurationPerMove)
	{
		FTundra_SimonSaysStage Stage;
		Manager.GetCurrentDanceStage(Stage);
		int SequenceIndex = Manager.GetCurrentDanceSequenceIndex();
		TArray<int> Sequence = Stage.Sequences[SequenceIndex].Sequence;

		int PreviousTileIndex = -1;
		for(int MoveIndex = 0; MoveIndex < Sequence.Num(); MoveIndex++)
		{
			int CurrentTileIndex = Sequence[MoveIndex];
			 if(MonkeyJumpedOverCenterTile(CurrentTileIndex, PreviousTileIndex))
			 	MonkeyKingJump(BeatDurationPerMove, 0, false);

			MonkeyKingJump(BeatDurationPerMove, CurrentTileIndex, false);
			PreviousTileIndex = CurrentTileIndex;
		}

		MonkeyKingJump(BeatDurationPerMove, 0, true);
	}

	void DeactivateSimonSays()
	{
		FTundra_SimonSaysStateDeactivateData Data;
		StateComp.StateQueue.Queue(Data);
	}

	void Delay(int DelayInBeats, FName DebugDelayName)
	{
		FTundra_SimonSaysStateUnspecifiedDelayData Data;
		Data.DelayInBeats = DelayInBeats;
		Data.DebugDelayName = DebugDelayName;
		StateComp.StateQueue.Queue(Data);
	}

	void MonkeyLightUpTile(int BeatDuration, int TileIndex, bool bIsLast)
	{
		FTundra_SimonSaysStateMonkeyTileLightUpData Data;
		Data.BeatDuration = BeatDuration;
		Data.TileIndex = TileIndex;
		Data.bIsLast = bIsLast;
		StateComp.StateQueue.Queue(Data);
	}

	void MonkeyKingJump(int BeatDuration, int TileIndex, bool bIsLast)
	{
		FTundra_SimonSaysStateMonkeyKingDanceData Data;
		Data.BeatDuration = BeatDuration;
		Data.TileIndex = TileIndex;
		Data.bIsLast = bIsLast;
		StateComp.StateQueue.Queue(Data);
	}

	void PlayerTurn(float BeatDurationMultiplier)
	{
		FTundra_SimonSaysStatePlayerTurnData Data;
		Data.PlayerSequenceBeatMultiplier = BeatDurationMultiplier;
		StateComp.StateQueue.Queue(Data);
	}

	void PlayerToMonkeyPlayerStatus(int BeatDuration)
	{
		FTundra_SimonSaysStatePlayerToMonkeyPlayerStatusData Data;
		Data.BeatDuration = BeatDuration;
		StateComp.StateQueue.Queue(Data);
	}

	bool MonkeyJumpedOverCenterTile(int CurrentIndex, int PreviousIndex) const
	{
		if(PreviousIndex == -1)
			return false;

		if(MonkeyStartedAndOrLandedOn(CurrentIndex, PreviousIndex, 1, 4))
			return true;

		if(MonkeyStartedAndOrLandedOn(CurrentIndex, PreviousIndex, 2, 3))
			return true;

		return false;
	}

	/* True if current index is either IndexA or IndexB and previous index is the opposite one. */
	bool MonkeyStartedAndOrLandedOn(int CurrentIndex, int PreviousIndex, int IndexA, int IndexB) const
	{
		return (CurrentIndex == IndexA && PreviousIndex == IndexB) || (CurrentIndex == IndexB && PreviousIndex == IndexA);
	}
}

UCLASS(Abstract)
class UTundra_SimonSaysStateBaseCapability : UHazeCapability
{
	ATundra_SimonSaysManager Manager;
	UTundra_SimonSaysStateManagerComponent StateComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = TundraSimonSays::GetManager();
		StateComp = UTundra_SimonSaysStateManagerComponent::GetOrCreate(Manager);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundra_SimonSaysStateDeactivatedParams& Params) const
	{
		if(!StateComp.StateQueue.IsActive(this))
		{
			Params.StateDuration = GetStateTotalTime();
			return true;
		}

		if(Manager.GetCurrentStateActiveDuration() >= GetStateTotalTime())
		{
			Params.StateDuration = GetStateTotalTime();
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundra_SimonSaysStateDeactivatedParams Params)
	{
		Manager.CompletedStatesTotalDuration += Params.StateDuration;
	}

	int GetStateAmountOfBeats() const { return 0; }

	float GetStateTotalTime() const final
	{
		return Manager.GetRealTimeBetweenBeats() * GetStateAmountOfBeats();
	}
}

struct FTundra_SimonSaysStateDeactivatedParams
{
	float StateDuration;
}