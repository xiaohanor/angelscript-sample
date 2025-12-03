struct FTundra_SimonSaysSequence
{
	UPROPERTY()
	TArray<int> Sequence;
}

struct FTundra_SimonSaysStage
{
	UPROPERTY()
	float BeatsPerMinuteMultiplier = 1.0;

	UPROPERTY()
	TArray<FTundra_SimonSaysSequence> Sequences;
}

struct FTundra_SimonSaysTileStage
{
	UPROPERTY()
	TArray<FTundra_SimonSaysTileData> Tiles;
}

struct FTundra_SimonSaysTileData
{
	UPROPERTY()
	ACongaDanceFloorTile Tile;
}

struct FTundra_SimonSaysActiveKillEffectData
{
	UNiagaraComponent Niagara;
	float TimeOfActivate;
	float DurationToBeActive;

	bool ShouldDeactivate()
	{
		return Time::GetGameTimeSince(TimeOfActivate) >= DurationToBeActive;
	}
}

struct FTundra_SimonSaysTileKillReactionData
{
	AHazePlayerCharacter PlayerToKill;
	float TimeOfStartReaction;
	FVector OriginalLocation;
}

struct FTundra_SimonSaysSettingsData
{
	UPROPERTY()
	UHazeComposableSettings Settings;

	UPROPERTY()
	EHazeSettingsPriority Priority = EHazeSettingsPriority::Gameplay;
}

enum ETundra_SimonSaysState
{
	None,
	MovePlatforms,
	WaitForPlayersToJump,
	UnspecifiedDelay,
	CameraToMonkey,
	MonkeyTurn,
	CameraToPlayer,
	PlayerTurn,
	PlayerToMonkeyPlayerStatus,
	MonkeySuccess,
	DanceFloorWave,
	MoveMonkeyKingPlatforms
}

struct FTundra_SimonSaysMonkeyKingMoveData
{
	bool bShouldBeActive = false;
	int TargetTileIndex = -1;
	float MoveAlpha;
}

struct FTundra_SimonSaysMovingTileData
{
	FInstigator Instigator;
	bool bHasExtraData = false;
	bool bMoveUp;
	float TimeOfStartMove;
	float TotalMoveDuration;
	FRuntimeFloatCurve MoveCurve;
	FVector Origin;
	FVector Destination;
}

event void FTundra_SimonSaysEventNoParams();
event void FTundra_SimonSaysPlayerMeasureEnd(AHazePlayerCharacter Player, bool bSuccessful);
event void FTundra_SimonSaysEventNextStage(int NewStageIndex);
event void FTundra_SimonSaysEventWin();
event void FTundra_SimonSaysEventChangeMainState(ETundra_SimonSaysState PreviousMainState, ETundra_SimonSaysState CurrentMainState);
event void FTundra_SimonSaysEventChangeSecondaryState(ETundra_SimonSaysState SecondaryState);

namespace Tundra_SimonSaysDevToggles
{
	const FHazeDevToggleCategory SimonSaysCategory = FHazeDevToggleCategory(n"Simon Says");
	const FHazeDevToggleBool SimonSaysIgnoreZoePerformance = FHazeDevToggleBool(SimonSaysCategory, n"Ignore Zoe Performance");
}

UCLASS(Abstract)
class ATundra_SimonSaysManager : AHazeActor
{
	access TileMoveCapability = private, UTundra_SimonSaysStateTileMoveCapability;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.SetSpriteName("S_Player");

	UPROPERTY(DefaultComponent)
	UTundra_SimonSaysManagerVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_SimonSaysStateManagerCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_SimonSaysStateMonkeyTileLightUpCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_SimonSaysStatePlayerTurnCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_SimonSaysStateUnspecifiedDelayCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_SimonSaysStatePlayerToMonkeyPlayerStatusCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_SimonSaysStateTileMoveCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_SimonSaysStateMonkeyToPlayerCameraCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_SimonSaysStatePlayerToMonkeyCameraCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_SimonSaysStateMonkeySuccessAnimationCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_SimonSaysStateMonkeyKingDanceCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_SimonSaysStateDanceFloorWaveCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_SimonSaysStateMonkeyKingTileMoveCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_SimonSaysStateDeactivateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_SimonSaysStateWaitForPlayersToJumpToNextStageCapability");

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor MonkeyCamera;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem KillEffect;

	UPROPERTY(EditDefaultsOnly)
	FVector KillEffectWorldOffset;

	UPROPERTY(EditDefaultsOnly)
	FVector KillEffectWorldScale = FVector(1.0);

	UPROPERTY(EditDefaultsOnly)
	float KillEffectBeatDuration = 0.5;

	/* If true, the kill effect will be deactivated immediately, if false it will just call deactivate which will fade out the vfx (if it has support for this) */
	UPROPERTY(EditDefaultsOnly)
	bool bKillEffectDeactivateImmediate = true;

	UPROPERTY(EditAnywhere)
	TArray<FTundra_SimonSaysTileStage> TileStagesMio;

	UPROPERTY(EditAnywhere)
	TArray<FTundra_SimonSaysTileStage> TileStagesZoe;

	UPROPERTY(EditAnywhere)
	TArray<ATundra_SimonSaysMonkeyKingTile> TileStageMonkeyKing;

	/* These actors position will be set to the x/y location of Mio's center tile of the current stage */
	UPROPERTY(EditAnywhere)
	TArray<AActor> ActorsToMatchMioTilesCenter;

	/* These actors position will be set to the x/y location of Zoe's center tile of the current stage */
	UPROPERTY(EditAnywhere)
	TArray<AActor> ActorsToMatchZoeTilesCenter;

	/* These actors will be activated during the player measure and be disabled during the monkey measure */
	UPROPERTY(EditAnywhere)
	TArray<AHazeActor> ActorsToActivateInPlayerMeasure;

	/* These actors will be activated during the player measure and be disabled during the monkey measure */
	UPROPERTY(EditAnywhere)
	TArray<AHazeActor> ActorsToActivateInMonkeyMeasure;

	UPROPERTY(EditDefaultsOnly)
	TArray<FTundra_SimonSaysSettingsData> SettingsToApplyOnMio;

	UPROPERTY(EditDefaultsOnly)
	TArray<FTundra_SimonSaysSettingsData> SettingsToApplyOnZoe;

	UPROPERTY(EditAnywhere)
	TArray<int> ColorIndicesForTiles;

	/* These tiles will always be lit and wont generate any hit events (so don't include these in the sequences) */
	UPROPERTY(EditAnywhere)
	TArray<int> IgnoredTiles;
	default IgnoredTiles.Add(0);

	UPROPERTY(EditAnywhere, Category = "Settings")
	private int BeatsPerMinute = 30;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "!bSeparateSequenceForEachPlayer", EditConditionHides))
	TArray<FTundra_SimonSaysStage> DanceStages;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UForceFeedbackEffect BeatRumble;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UForceFeedbackEffect BigRumble;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float BeatRumbleTimeOffset = -0.05;

	UPROPERTY(EditAnywhere, Category = "Settings|Tile Vertical Movement")
	float TileMoveUpDistance = 400.0;

	/* This curve will determine the interpolation of the tiles vertical movement when they are moved up the base move up distance. */
	UPROPERTY(EditAnywhere, Category = "Settings|Tile Vertical Movement")
	FRuntimeFloatCurve TileMoveUpCurve;
	default TileMoveUpCurve.AddDefaultKey(0.0, 0.0);
	default TileMoveUpCurve.AddDefaultKey(1.0, 1.0);

	/* This curve will determine the interpolation of the tiles vertical movement when they are moved down the base move up distance. */
	UPROPERTY(EditAnywhere, Category = "Settings|Tile Vertical Movement")
	FRuntimeFloatCurve TileMoveDownCurve;
	default TileMoveDownCurve.AddDefaultKey(0.0, 0.0);
	default TileMoveDownCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Settings|Tile Vertical Movement")
	float CurveAlphaToEnablePerchOnMoveUp = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings|Tile Vertical Movement")
	float CurveAlphaToDisablePerchOnMoveDown = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings|Tile Kill Reaction")
	float TileKillReactionBeatDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bDebug = true;

	UPROPERTY()
	FTundra_SimonSaysEventNoParams OnPlayerPolesStartMoveDown;

	UPROPERTY()
	FTundra_SimonSaysEventNoParams OnPlayerPolesStopMovingUp;

	UPROPERTY()
	FTundra_SimonSaysEventNoParams OnPlayerMeasureStart;

	UPROPERTY()
	FTundra_SimonSaysEventNoParams OnPlayerMeasureEnd;

	UPROPERTY()
	FTundra_SimonSaysPlayerMeasureEnd OnPlayerEndedMeasure;

	UPROPERTY()
	FTundra_SimonSaysEventNoParams OnBothPlayersSuccessful;

	UPROPERTY()
	FTundra_SimonSaysEventNoParams OnEitherPlayerFailed;
	
	UPROPERTY()
	FTundra_SimonSaysEventNoParams OnMonkeyMeasureStart;

	UPROPERTY()
	FTundra_SimonSaysEventNoParams OnMonkeyMeasureEnd;

	UPROPERTY()
	FTundra_SimonSaysEventNextStage OnNextStage;
	
	UPROPERTY()
	FTundra_SimonSaysEventWin OnWinSimonSays;

	UPROPERTY()
	FTundra_SimonSaysEventChangeMainState OnChangeMainState;

	UPROPERTY()
	FTundra_SimonSaysEventChangeSecondaryState OnStartSecondaryState;

	UPROPERTY()
	FTundra_SimonSaysEventChangeSecondaryState OnEndSecondaryState;

	UPROPERTY()
	FTundra_SimonSaysEventNextStage OnCameraMoveToNextStage;

	float ProgressAlpha;
	bool bShouldSnapPlatformsOnActivated = false;
	bool bShouldSnapPlatformsOnDeactivated = false;
	float CompletedStatesTotalDuration = 0.0;
	bool bHasEverBeenActive = false;
	TMap<ACongaDanceFloorTile, FTundra_SimonSaysTileKillReactionData> ActiveKillReactionTiles;
	bool bDeactivatePending = false;
	FTundra_SimonSaysMonkeyKingMoveData MonkeyKingMoveData;

	private ETundra_SimonSaysState Internal_CurrentMainState = ETundra_SimonSaysState::None;
	private ETundra_SimonSaysState Internal_CurrentSecondaryState = ETundra_SimonSaysState::None;
	
	private bool bIsActive = false;
	private int CurrentDanceSequenceIndex = 0;
	private int CurrentDanceStageIndex = 0;
	private int QuarterMeasureSequenceWasPicked = -1;
	private float ActivateTime;
	private TSet<ACongaDanceFloorTile> ColorOverriddenTiles;
	private TSet<ACongaDanceFloorTile> ColorOverriddenTilesToClear;
	private TArray<FTundra_SimonSaysActiveKillEffectData> ActiveKillEffects;
	private TMap<ACongaDanceFloorTile, FTundra_SimonSaysMovingTileData> MovingTiles;
	private TSet<ACongaDanceFloorTile> ColoredIgnoredTiles;
	private TSet<ACongaDanceFloorTile> UpTiles;
	private TPerPlayer<FTundra_SimonSaysTileStage> TilesToDisplayStatusPerPlayer;

	UTundra_SimonSaysPlayerComponent MioSimonSaysComp;
	UTundra_SimonSaysPlayerComponent ZoeSimonSaysComp;
	TPerPlayer<UTundra_SimonSaysPlayerComponent> PlayerSimonSaysComps;
	ATundra_SimonSaysMonkeyKing MonkeyKing;
	TMap<AHazeActor, UTundra_SimonSaysAnimDataComponent> AnimComps;
	TArray<ACongaDanceFloorTile> AllIgnoredTiles;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PrepareMonkeysTiles();
		PreparePlayersTiles(Game::Mio);
		PreparePlayersTiles(Game::Zoe);

		AnimComps.Add(Game::Mio, UTundra_SimonSaysAnimDataComponent::GetOrCreate(Game::Mio));
		AnimComps.Add(Game::Zoe, UTundra_SimonSaysAnimDataComponent::GetOrCreate(Game::Zoe));

		MioSimonSaysComp = UTundra_SimonSaysPlayerComponent::GetOrCreate(Game::Mio);
		ZoeSimonSaysComp = UTundra_SimonSaysPlayerComponent::GetOrCreate(Game::Zoe);
		PlayerSimonSaysComps[Game::Mio] = MioSimonSaysComp;
		PlayerSimonSaysComps[Game::Zoe] = ZoeSimonSaysComp;

		OnPlayerMeasureStart.AddUFunction(this, n"PlayerMeasureStart");
		OnPlayerMeasureEnd.AddUFunction(this, n"PlayerMeasureEnd");
		OnBothPlayersSuccessful.AddUFunction(this, n"BothPlayersSuccessful");

		OnMonkeyMeasureStart.AddUFunction(this, n"MonkeyMeasureStart");
		OnMonkeyMeasureEnd.AddUFunction(this, n"MonkeyMeasureEnd");

		SetActorArrayActive(ActorsToActivateInMonkeyMeasure, false);
		SetActorArrayActive(ActorsToActivateInPlayerMeasure, false);

		for(int i = 0; i < TileStagesMio.Num(); i++)
		{
			GetIgnoredTiles(AllIgnoredTiles, i, false);
		}

		Tundra_SimonSaysDevToggles::SimonSaysIgnoreZoePerformance.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		HandleKillEffects();
		HandleTileKillReactions();

		if(!IsActive())
			return;

#if EDITOR
		if(bDebug)
		{
			PrintToScreen(f"Current Simon Says Secondary State: {GetSecondaryState()}");
			PrintToScreen(f"Current Simon Says Main State: {GetMainState()}");
		}
#endif
	}

	private void HandleTileKillReactions()
	{
		TArray<ACongaDanceFloorTile> TilesToRemove;
		for(auto Pair : ActiveKillReactionTiles)
		{
			FTundra_SimonSaysTileKillReactionData Data = Pair.Value;

			float Alpha = Math::Saturate(Time::GetGameTimeSince(Data.TimeOfStartReaction) / TileKillReactionBeatDuration);
			float MoveAlpha = TileMoveDownCurve.GetFloatValue(Alpha);
			Pair.Key.ActorLocation = Math::Lerp(Data.OriginalLocation, Data.OriginalLocation + FVector::DownVector * TileMoveUpDistance, MoveAlpha);

			if(Data.PlayerToKill.HasControl() && Alpha == 1.0)
			{
				TilesToRemove.Add(Pair.Key);
			}
		}

		for(ACongaDanceFloorTile Tile : TilesToRemove)
		{
			CrumbEndTileKillReaction(Tile);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbEndTileKillReaction(ACongaDanceFloorTile Tile)
	{
		// If the guest player died and the tiles have started moving on the host side the kill reaction wont exist on the host side.
		if(!ActiveKillReactionTiles.Contains(Tile))
			return;

		FTundra_SimonSaysTileKillReactionData Data = ActiveKillReactionTiles[Tile];
		ActiveKillReactionTiles.Remove(Tile);
		
		Tile.ActorLocation = Data.OriginalLocation + FVector::DownVector * TileMoveUpDistance;
		Tile.SimonSaysTargetable.Disable(this);
		Data.PlayerToKill.UnblockCapabilities(TundraSimonSays::SimonSaysPerchJump, this);
		AnimComps[Data.PlayerToKill].AnimData.bIsFalling = false;

		EndTileMove(Tile, this);
	}

	private void HandleKillEffects()
	{
		for(int i = ActiveKillEffects.Num() - 1; i >= 0; i--)
		{
			if(ActiveKillEffects[i].ShouldDeactivate())
			{
				if(bKillEffectDeactivateImmediate)
					ActiveKillEffects[i].Niagara.DeactivateImmediate();
				else
					ActiveKillEffects[i].Niagara.Deactivate();
				
				ActiveKillEffects.RemoveAt(i);
			}
		}
	}

	UFUNCTION()
	private void BothPlayersSuccessful()
	{
		if(!HasControl())
			return;

		CrumbIncrementSequence();
	}

	private void SetActorArrayActive(TArray<AHazeActor>& ActorArray, bool bActive)
	{
		for(int i = 0; i < ActorArray.Num(); i++)
		{
			AHazeActor Actor = ActorArray[i];

			if(bActive)
				Actor.RemoveActorDisable(this);
			else
				Actor.AddActorDisable(this);
		}
	}

	UFUNCTION()
	private void PlayerMeasureStart()
	{
		SetActorArrayActive(ActorsToActivateInPlayerMeasure, true);
	}

	UFUNCTION()
	private void PlayerMeasureEnd()
	{
		SetActorArrayActive(ActorsToActivateInPlayerMeasure, false);
	}

	UFUNCTION()
	private void MonkeyMeasureStart()
	{
		SetActorArrayActive(ActorsToActivateInMonkeyMeasure, true);
	}

	UFUNCTION()
	private void MonkeyMeasureEnd()
	{
		SetActorArrayActive(ActorsToActivateInMonkeyMeasure, false);
	}

	void OnClearStatusOnTiles()
	{
		TArray<FTundra_SimonSaysTileData>& MioStatusTiles = TilesToDisplayStatusPerPlayer[Game::Mio].Tiles;
		TArray<FTundra_SimonSaysTileData>& ZoeStatusTiles = TilesToDisplayStatusPerPlayer[Game::Zoe].Tiles;

		for(FTundra_SimonSaysTileData Tile : MioStatusTiles)
		{
			Tile.Tile.ClearColorOverride(this);
			Tile.Tile.Disable(this);
		}

		for(FTundra_SimonSaysTileData Tile : ZoeStatusTiles)
		{
			Tile.Tile.ClearColorOverride(this);
			Tile.Tile.Disable(this);
		}

		MioStatusTiles.Reset();
		ZoeStatusTiles.Reset();
	}

	void UpdateTileStatusForPlayer(AHazePlayerCharacter Player, bool bEndOfTurn = false)
	{
		if(!HasControl())
			return;

		if(!bEndOfTurn && !PlayerSimonSaysComps[Player].HasSucceeded() && !PlayerSimonSaysComps[Player].HasFailed())
			return;

		CrumbUpdateTileStatus(Player, PlayerSimonSaysComps[Player].HasSucceeded());
	}

	UFUNCTION(CrumbFunction)
	private void CrumbUpdateTileStatus(AHazePlayerCharacter Player, bool bSucceeded)
	{
		TArray<FTundra_SimonSaysTileData>& StatusTiles = TilesToDisplayStatusPerPlayer[Player].Tiles;

		// Only get current tiles if we don't have any current tiles!
		if(StatusTiles.Num() == 0)
		{
			GetTilesForPlayer(Player, StatusTiles);

			for(int i = StatusTiles.Num() - 1; i >= 0; --i)
			{
				if(IgnoredTiles.Contains(i))
					StatusTiles.RemoveAt(i);
			}
		}

		for(FTundra_SimonSaysTileData Tile : StatusTiles)
		{
			Tile.Tile.ApplyColorOverride(bSucceeded ? FLinearColor::Green : FLinearColor::Red, this, EInstigatePriority::Override);
			Tile.Tile.Enable(this);
		}
	}

	// All of this extra data is so we can predict the point the tile will be at when jumping towards a moving tile.
	bool PrepareTileMove(ACongaDanceFloorTile Tile, FInstigator Instigator, bool bMoveUp, float TotalMoveDuration, FRuntimeFloatCurve MoveCurve, FVector Origin, FVector Destination)
	{
		if(IsTileBeingMoved(Tile))
			return false;

		FTundra_SimonSaysMovingTileData Data;
		Data.Instigator = Instigator;
		Data.bMoveUp = bMoveUp;
		Data.TimeOfStartMove = Time::GetGameTimeSeconds();
		Data.bHasExtraData = true;
		Data.TotalMoveDuration = TotalMoveDuration;
		Data.MoveCurve = MoveCurve;
		Data.Origin = Origin;
		Data.Destination = Destination;
		MovingTiles.Add(Tile, Data);
		return true;
	}

	bool PrepareTileMove(ACongaDanceFloorTile Tile, FInstigator Instigator)
	{
		if(IsTileBeingMoved(Tile))
			return false;

		FTundra_SimonSaysMovingTileData Data;
		Data.Instigator = Instigator;
		Data.TimeOfStartMove = Time::GetGameTimeSeconds();
		MovingTiles.Add(Tile, Data);
		return true;
	}

	bool IsTileBeingMoved(const ACongaDanceFloorTile Tile) const
	{
		return MovingTiles.Contains(Tile);
	}

#if !RELEASE
	FInstigator DebugGetTileMovingInstigator(ACongaDanceFloorTile Tile) const
	{
		devCheck(IsTileBeingMoved(Tile), "Tile is not being moved");
		return MovingTiles[Tile].Instigator;
	}
#endif

	FTundra_SimonSaysMovingTileData GetMovingTileData(ACongaDanceFloorTile Tile)
	{
#if EDITOR
		bool bMoving = IsTileBeingMoved(Tile);
		devCheck(bMoving, "Tried to GetMovingTileData when the tile isn't moving!");
		devCheck(MovingTiles[Tile].bHasExtraData, "Tried to GetMovingTileData when the tile has no extra move data!");
#endif
		return MovingTiles[Tile];
	}

	void EndTileMove(ACongaDanceFloorTile Tile, FInstigator Instigator)
	{
		bool bTileBeingMoved = IsTileBeingMoved(Tile);
		devCheck(bTileBeingMoved, "Tile isn't being moved");

		devCheck(MovingTiles[Tile].Instigator == Instigator, "Tried to end the moving of a tile with another instigator than the move was prepared with");
		MovingTiles.Remove(Tile);
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	void CrumbAddKillReactionTile(ACongaDanceFloorTile Tile, AHazePlayerCharacter Player)
	{
		if(!PrepareTileMove(Tile, this, false, TileKillReactionBeatDuration, TileMoveDownCurve, Tile.ActorLocation, Tile.GetOriginalLocation()))
			return;

		FTundra_SimonSaysTileKillReactionData Data;
		Data.TimeOfStartReaction = Time::GetGameTimeSeconds();
		Data.OriginalLocation = Tile.ActorLocation;
		Data.PlayerToKill = Player;
		ActiveKillReactionTiles.Add(Tile, Data);

		AnimComps[Player].AnimData.bIsFalling = true;

		Player.BlockCapabilities(TundraSimonSays::SimonSaysPerchJump, this);
	}

	void ChangeMainState(ETundra_SimonSaysState State)
	{
		if(State == Internal_CurrentMainState)
			return;

		ETundra_SimonSaysState PreviousState = Internal_CurrentMainState;
		Internal_CurrentMainState = State;
		OnChangeMainState.Broadcast(PreviousState, Internal_CurrentMainState);
	}

	void SetSecondaryState(ETundra_SimonSaysState State)
	{
		ETundra_SimonSaysState PreviousState = Internal_CurrentMainState;
		Internal_CurrentSecondaryState = State;
		if(Internal_CurrentSecondaryState == ETundra_SimonSaysState::None)
			OnEndSecondaryState.Broadcast(PreviousState);
		else
			OnStartSecondaryState.Broadcast(Internal_CurrentSecondaryState);
	}

	ETundra_SimonSaysState GetMainState() const property
	{
		return Internal_CurrentMainState;
	}

	ETundra_SimonSaysState GetSecondaryState() const property
	{
		return Internal_CurrentSecondaryState;
	}

	private void ResetStage()
	{
		for(ACongaDanceFloorTile Tile : ColorOverriddenTiles)
		{
			Tile.Disable(Tile);
			AHazePlayerCharacter HostPlayer = Network::HasWorldControl() ? Game::FirstLocalPlayer : Game::FirstLocalPlayer.OtherPlayer;
			Tile.SetActorControlSide(HostPlayer);
		}

		ColorOverriddenTilesToClear = ColorOverriddenTiles;
	}

	access:TileMoveCapability
	void ClearColorsOfOldStage(int StageIndex)
	{
		for(ACongaDanceFloorTile Tile : ColorOverriddenTilesToClear)
		{
			Tile.ClearColorOverride(GetColorInstigatorForTiles(StageIndex));
		}

		ColorOverriddenTilesToClear.Empty();
	}

	private void Internal_OnNextStage()
	{
		ResetStage();

		PreparePlayersTilesForNextStage(Game::Mio);
		PreparePlayersTilesForNextStage(Game::Zoe);

		for(AActor Actor : ActorsToMatchMioTilesCenter)
		{
			FVector Location = GetTileForPlayer(Game::Mio, 0).ActorLocation;
			Actor.ActorLocation = FVector(Location.X, Location.Y, Actor.ActorLocation.Z);
		}

		for(AActor Actor : ActorsToMatchZoeTilesCenter)
		{
			FVector Location = GetTileForPlayer(Game::Zoe, 0).ActorLocation;
			Actor.ActorLocation = FVector(Location.X, Location.Y, Actor.ActorLocation.Z);
		}

		OnNextStage.Broadcast(CurrentDanceStageIndex);
		FTundra_SimonSaysManagerOnNextStageEffectParams Params;
		Params.CurrentStageIndex = CurrentDanceStageIndex;
		UTundra_SimonSaysManagerEffectHandler::Trigger_OnNextStage(this, Params);
	}

	private void PrepareMonkeysTiles()
	{
		TArray<ATundra_SimonSaysMonkeyKingTile> Tiles;
		GetTilesForMonkeyKing(Tiles);

		for(int i = 0; i < Tiles.Num(); i++)
		{
			ATundra_SimonSaysMonkeyKingTile Tile = Tiles[i];
			Tile.ApplyColorOverride(ColorIndicesForTiles[i], this);
		}
	}

	private void PreparePlayersTiles(AHazePlayerCharacter Player)
	{
		const TArray<FTundra_SimonSaysTileStage>& Stage = Player.IsMio() ? TileStagesMio : TileStagesZoe;
		for(int i = 0; i < Stage.Num(); i++)
		{
			const TArray<FTundra_SimonSaysTileData>& Tiles = Stage[i].Tiles;
			for(FTundra_SimonSaysTileData Tile : Tiles)
			{
				Tile.Tile.SimonSaysTargetable.StageIndex = i;
			}
		}
	}

	private void ResetMonkeysTiles()
	{
		TArray<ATundra_SimonSaysMonkeyKingTile> Tiles;
		GetTilesForMonkeyKing(Tiles);

		for(int i = 0; i < Tiles.Num(); i++)
		{
			ATundra_SimonSaysMonkeyKingTile Tile = Tiles[i];
			Tile.ClearColorOverride(this);
		}
	}

	private void PreparePlayersTilesForNextStage(AHazePlayerCharacter Player)
	{
		TArray<FTundra_SimonSaysTileData> Tiles;
		GetTilesForPlayer(Player, Tiles);
		int CurrentStage = GetCurrentDanceStageIndex();

		for(int i = 0; i < Tiles.Num(); i++)
		{
			FTundra_SimonSaysTileData Tile = Tiles[i];
			Tile.Tile.SetActorControlSide(Player);
			Tile.Tile.ApplyColorOverride(ColorIndicesForTiles[i], GetColorInstigatorForTiles(CurrentStage));
			Tile.Tile.SimonSaysTargetable.Enable(Tile.Tile);
			Tile.Tile.SimonSaysTargetable.Disable(this);
			Tile.Tile.SimonSaysTargetable.SetUsableByPlayers(Player.IsMio() ? EHazeSelectPlayer::Mio : EHazeSelectPlayer::Zoe);
			ColorOverriddenTiles.Add(Tile.Tile);
		}
	}

	private void ApplyIgnoredTilesColor()
	{
		devCheck(ColoredIgnoredTiles.Num() == 0, "Tried to apply ignored tiles color when colored ignored tiles array is already filled.");

		for(int IgnoredIndex : IgnoredTiles)
		{
			for(int i = 0; i < TileStagesMio.Num(); i++)
			{
				ColoredIgnoredTiles.Add(GetTileForPlayer(Game::Mio, i, IgnoredIndex));
				ColoredIgnoredTiles.Add(GetTileForPlayer(Game::Zoe, i, IgnoredIndex));
			}
		}

		for(ACongaDanceFloorTile Tile : ColoredIgnoredTiles)
		{
			Tile.ApplyColorOverride(-1, this, EInstigatePriority::High);
		}
	}

	private void ClearIgnoredTilesColor()
	{
		for(ACongaDanceFloorTile Tile : ColoredIgnoredTiles)
		{
			Tile.ClearColorOverride(this);
		}

		ColoredIgnoredTiles.Empty();
	}

	private FName GetColorInstigatorForTiles(int StageIndex)
	{
		return FName("SimonSaysManager_StageIndex_" + StageIndex);
	}

	void AddProgressAlpha(float AlphaToAdd)
	{
		ProgressAlpha += AlphaToAdd;
		ProgressAlpha = Math::Saturate(ProgressAlpha);
	}

	UFUNCTION(BlueprintCallable)
	void ShowMonkeyKing()
	{
		MonkeyKing.RemoveActorDisable(this);
	}

	void Activate(bool bSnapPlatforms = true)
	{
		// Activate monkey king not crumbed so it doesn't disappear
		MonkeyKing.RemoveActorDisable(this);

		if(!HasControl())
			return;

		CrumbActivate(bSnapPlatforms);
	}

	void Deactivate(bool bSnapPlatforms = true)
	{
		if(!HasControl())
			return;

		CrumbDeactivate(bSnapPlatforms);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivate(bool bSnapPlatforms)
	{
		bHasEverBeenActive = true;
		CompletedStatesTotalDuration = 0.0;
		bShouldSnapPlatformsOnActivated = bSnapPlatforms;

		RequestCapabilityComp.StartInitialSheetsAndCapabilities(Game::GetMio(), this);
		RequestCapabilityComp.StartInitialSheetsAndCapabilities(Game::GetZoe(), this);

		for(AHazePlayerCharacter Player : Game::Players)
		{
			Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
			Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
			Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big, false);
			UTundraPlayerShapeshiftingComponent::Get(Player).AddSpawnAsHumanBlocker(this);

			TArray<FTundra_SimonSaysSettingsData>& SettingsArray = Player.IsMio() ? SettingsToApplyOnMio : SettingsToApplyOnZoe;
			for(FTundra_SimonSaysSettingsData& Data : SettingsArray)
			{
				Player.ApplySettings(Data.Settings, this, Data.Priority);
			}
		}

		bIsActive = true;
		ActivateTime = Time::GameTimeSeconds;

		ApplyIgnoredTilesColor();

		Internal_OnNextStage();
		OnMonkeyMeasureStart.Broadcast();
		UTundra_SimonSaysManagerEffectHandler::Trigger_OnSimonSaysStarted(this);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDeactivate(bool bSnapPlatforms)
	{
		bShouldSnapPlatformsOnDeactivated = bSnapPlatforms;

		MonkeyKing.AddActorDisable(this);

		RequestCapabilityComp.StopInitialSheetsAndCapabilities(Game::GetMio(), this);
		RequestCapabilityComp.StopInitialSheetsAndCapabilities(Game::GetZoe(), this);

		for(AHazePlayerCharacter Player : Game::Players)
		{
			Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
			UTundraPlayerShapeshiftingComponent::Get(Player).RemoveSpawnAsHumanBlocker(this);
			Player.ClearSettingsByInstigator(this);
		}
		
		bIsActive = false;

		Game::Mio.ClearSettingsByInstigator(this);
		Game::Zoe.ClearSettingsByInstigator(this);

		ClearIgnoredTilesColor();
		ResetMonkeysTiles();

		ResetStage();
		SetActorArrayActive(ActorsToActivateInMonkeyMeasure, false);
		SetActorArrayActive(ActorsToActivateInPlayerMeasure, false);
	}

	void PlayKillEffectOnTile(ACongaDanceFloorTile Tile)
	{
		FVector Location = Tile.Mesh.WorldLocation;
        Location += KillEffectWorldOffset;
		UNiagaraComponent Niagara = Niagara::SpawnLoopingNiagaraSystemAttachedAtLocation(KillEffect, Tile.RootComponent, Location);
		Niagara.WorldScale3D = KillEffectWorldScale;

		FTundra_SimonSaysActiveKillEffectData Data;
		Data.Niagara = Niagara;
		Data.TimeOfActivate = Time::GetGameTimeSeconds();
		Data.DurationToBeActive = KillEffectBeatDuration * GetRealTimeBetweenBeats();
		ActiveKillEffects.Add(Data);
	}

	bool IsTileCurrentlyIgnored(ACongaDanceFloorTile Tile)
	{
		TArray<ACongaDanceFloorTile> Tiles;
		GetIgnoredTiles(Tiles, CurrentDanceStageIndex);
		return Tiles.Contains(Tile);
	}

	bool WasTileIgnoredLastStage(ACongaDanceFloorTile Tile)
	{
		TArray<ACongaDanceFloorTile> Tiles;
		GetIgnoredTiles(Tiles, CurrentDanceStageIndex - 1);
		return Tiles.Contains(Tile);
	}

	/* Will return true if the given tile is ignored in any of the stages */
	bool CanTileEverBeIgnored(ACongaDanceFloorTile Tile)
	{
		return AllIgnoredTiles.Contains(Tile);
	}

	void GetIgnoredTiles(TArray<ACongaDanceFloorTile>& Tiles, int StageIndex, bool bEmptyArray = true)
	{
		if(bEmptyArray)
			Tiles.Empty();

		TArray<FTundra_SimonSaysTileData> MioTiles;
		TArray<FTundra_SimonSaysTileData> ZoeTiles;
		GetTilesForStage(Game::Mio, StageIndex, MioTiles);
		GetTilesForStage(Game::Zoe, StageIndex, ZoeTiles);

		for(int i = 0; i < IgnoredTiles.Num(); i++)
		{
			Tiles.Add(MioTiles[IgnoredTiles[i]].Tile);
			Tiles.Add(ZoeTiles[IgnoredTiles[i]].Tile);
		}
	}

	void GetTilesForMonkeyKing(TArray<ATundra_SimonSaysMonkeyKingTile>& TileData)
	{
		TileData = TileStageMonkeyKing;
	}

	void GetTilesForPlayer(AHazePlayerCharacter Player, TArray<FTundra_SimonSaysTileData>& FloorTiles)
	{
		if(Player.IsMio())
		{
			FloorTiles = TileStagesMio[CurrentDanceStageIndex].Tiles;
			return;
		}
		
		FloorTiles = TileStagesZoe[CurrentDanceStageIndex].Tiles;
	}

	void GetCurrentTileStageForPlayer(AHazePlayerCharacter Player, FTundra_SimonSaysTileStage& Stage)
	{
		if(Player.IsMio())
			Stage = TileStagesMio[CurrentDanceStageIndex];
		else
			Stage = TileStagesZoe[CurrentDanceStageIndex];
	}

	void GetTilesForStage(AHazePlayerCharacter Player, int StageIndex, TArray<FTundra_SimonSaysTileData>& FloorTiles)
	{
		if(Player.IsMio())
		{
			FloorTiles = TileStagesMio[StageIndex].Tiles;
			return;
		}
		
		FloorTiles = TileStagesZoe[StageIndex].Tiles;
	}

	ACongaDanceFloorTile GetTileForPlayer(AHazePlayerCharacter Player, int Index)
	{
		TArray<FTundra_SimonSaysTileData> Tiles;
		GetTilesForPlayer(Player, Tiles);
		return Tiles[Index].Tile;
	}

	ACongaDanceFloorTile GetTileForPlayer(AHazePlayerCharacter Player, int StageIndex, int TileIndex)
	{
		TArray<FTundra_SimonSaysTileData> Tiles;
		GetTilesForStage(Player, StageIndex, Tiles);
		return Tiles[TileIndex].Tile;
	}

	void GetDanceSequences(TArray<FTundra_SimonSaysSequence>& Sequences, int StageIndex) const
	{
		Sequences = DanceStages[StageIndex].Sequences;
	}

	void AddUpTile(ACongaDanceFloorTile Tile)
	{
		UpTiles.Add(Tile);
	}

	void RemoveUpTile(ACongaDanceFloorTile Tile)
	{
		UpTiles.Remove(Tile);
	}

	bool IsUpTile(ACongaDanceFloorTile Tile)
	{
		return UpTiles.Contains(Tile);
	}

	bool IsActive() const
	{
		return bIsActive;
	}

	void GetCurrentDanceSequence(FTundra_SimonSaysSequence& SimonSaysSequence) const
	{
		int SequenceIndex = GetCurrentDanceSequenceIndex();
		int StageIndex = GetCurrentDanceStageIndex();
		GetDanceSequence(SequenceIndex, SimonSaysSequence, StageIndex);
	}

	int GetCurrentDanceSequenceLength() const
	{
		FTundra_SimonSaysSequence Sequence;
		GetCurrentDanceSequence(Sequence);
		return Sequence.Sequence.Num();
	}

	int GetCurrentSequenceAmountInStage() const
	{
		int StageIndex = GetCurrentDanceStageIndex();
		TArray<FTundra_SimonSaysSequence> Sequences;
		GetDanceSequences(Sequences, StageIndex);
		return Sequences.Num();
	}

	void GetCurrentDanceStage(FTundra_SimonSaysStage& SimonSaysStage) const
	{
		SimonSaysStage = DanceStages[CurrentDanceStageIndex];
	}

	UFUNCTION(CrumbFunction)
	private void CrumbIncrementSequence()
	{
		int StageIndex = GetCurrentDanceStageIndex();
		int SequenceLength = GetCurrentSequenceAmountInStage();

		++CurrentDanceSequenceIndex;

		if(CurrentDanceSequenceIndex >= SequenceLength)
		{
			CurrentDanceSequenceIndex = 0;
			++CurrentDanceStageIndex;

			if(CurrentDanceStageIndex >= DanceStages.Num())
			{
				CurrentDanceStageIndex = DanceStages.Num() - 1;
				bDeactivatePending = true;
			}
			else
			{
				Internal_OnNextStage();
			}
		}
	}
	
	int GetCurrentDanceSequenceIndex() const
	{
		if(!IsActive())
			return -1;

		return CurrentDanceSequenceIndex;
	}

	int GetCurrentDanceStageIndex() const
	{
		if(!IsActive())
			return -1;

		return CurrentDanceStageIndex;
	}

	void GetDanceSequence(int SequenceIndex, FTundra_SimonSaysSequence& SimonSaysSequence, int StageIndex) const
	{
		TArray<FTundra_SimonSaysSequence> Sequences;
		GetDanceSequences(Sequences, StageIndex);
		SimonSaysSequence = Sequences[SequenceIndex];
	}

	float GetActiveDuration() const
	{
		if(!IsActive())
			return -1.0;
		
		return Time::GetGameTimeSince(ActivateTime);
	}

	float GetCurrentStateActiveDuration() const
	{
		if(!IsActive())
			return -1.0;

		return GetActiveDuration() - CompletedStatesTotalDuration;
	}

	float GetRealTimeBetweenBeats() const
	{
		return 1.0 / (GetActualBeatsPerMinute() / 60.0);
	}

	float GetActualBeatsPerMinute() const
	{
		return BeatsPerMinute * GetCurrentBeatsPerMinuteMultiplier();
	}

	float GetCurrentBeatsPerMinuteMultiplier() const
	{
		FTundra_SimonSaysStage Stage;
		GetCurrentDanceStage(Stage);
		return Stage.BeatsPerMinuteMultiplier;
	}

	int GetCurrentBeat() const
	{
		if(!IsActive())
			return -1;

		const int CurrentBeat = Math::CeilToInt(GetActiveDuration() / GetRealTimeBetweenBeats());
		
		return CurrentBeat;
	}

	float GetTimeToNextBeat() const
	{
		float BeatAlphaToNextBeat = 1.0 - Math::Fmod(GetActiveDuration(), GetRealTimeBetweenBeats()) / GetRealTimeBetweenBeats();

		return BeatAlphaToNextBeat * GetRealTimeBetweenBeats();
	}

	float GetTimeSinceLastBeat() const
	{
		float TimeToNextBeat = GetTimeToNextBeat();
		return GetRealTimeBetweenBeats() - TimeToNextBeat;
	}

	float GetBeatAlpha() const
	{
		if(!IsActive())
			return -1.0;

		return (GetActiveDuration() / GetRealTimeBetweenBeats()) % 1.0;
	}
}

#if EDITOR
	UCLASS(NotBlueprintable, NotPlaceable)
	class UTundra_SimonSaysManagerVisualizerComponent : UActorComponent
	{
		default bIsEditorOnly = true;
	}

	class UTundra_SimonSaysManagerVisualizer : UHazeScriptComponentVisualizer
	{
		default VisualizedClass = UTundra_SimonSaysManagerVisualizerComponent;

		UFUNCTION(BlueprintOverride)
		void VisualizeComponent(const UActorComponent Component)
		{
			auto Manager = Cast<ATundra_SimonSaysManager>(Component.Owner);

			for(int i = 0; i < Manager.TileStagesMio.Num(); i++)
			{
				TArray<FTundra_SimonSaysTileData> MioTiles;
				MioTiles = Manager.TileStagesMio[i].Tiles;
				FVector Offset = FVector::UpVector * (i * 250.0);
				DrawTiles(MioTiles, Manager.ColorIndicesForTiles, Offset);
			}

			for(int i = 0; i < Manager.TileStagesZoe.Num(); i++)
			{
				TArray<FTundra_SimonSaysTileData> ZoeTiles;
				ZoeTiles = Manager.TileStagesZoe[i].Tiles;
				FVector Offset = FVector::UpVector * (i * 250.0);
				DrawTiles(ZoeTiles, Manager.ColorIndicesForTiles, Offset);
			}
		}

		void DrawTiles(TArray<FTundra_SimonSaysTileData>& Tiles, const TArray<int>& Colors, FVector Offset)
		{
			for(int i = 0; i < Tiles.Num(); i++)
			{
				ACongaDanceFloorTile Tile = Tiles[i].Tile;
				if(Tile == nullptr)
					continue;

				FLinearColor ActualColor;
				Tile.GetColorByIndex(Colors[i], ActualColor);

				FVector Extent = Tile.GetActorBoxExtents(false);

				DrawWorldString(f"{i}", Tile.ActorLocation + FVector::UpVector * Extent.Z + Offset, ActualColor, 2.0, -1.0, false, true);
			}
		}
	}
#endif