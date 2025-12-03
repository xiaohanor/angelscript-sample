event void FCoastWaterskiStartStopWaterskiEvent(AHazePlayerCharacter Player);

UCLASS(Abstract)
class ACoastWaterskiManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditInstanceOnly)
	TArray<ASplineActor> RespawnSplines;

	UPROPERTY()
	FCoastWaterskiStartStopWaterskiEvent OnStartWaterski;

	UPROPERTY()
	FCoastWaterskiStartStopWaterskiEvent OnStopWaterski;

	bool bHasBegunPlay = false;
	TPerPlayer<UCoastWaterskiPlayerComponent> WaterskiComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WaterskiComps[EHazePlayer::Zoe] = UCoastWaterskiPlayerComponent::Get(Game::Zoe);
		WaterskiComps[EHazePlayer::Mio] = UCoastWaterskiPlayerComponent::Get(Game::Mio);
		WaterskiComps[EHazePlayer::Zoe].WaterskiManager = this;
		WaterskiComps[EHazePlayer::Mio].WaterskiManager = this;

		bHasBegunPlay = true;
	}

	UFUNCTION()
	void StartWaterskiing(AHazePlayerCharacter Player, USceneComponent WaterskiAttachPoint, bool bCameFromWingsuit = false)
	{
		devCheck(bHasBegunPlay, "Can't start waterski before begin play has run");

		WaterskiComps[Player].StartWaterskiing(WaterskiAttachPoint, bCameFromWingsuit);
	}

	UFUNCTION()
	void StopWaterskiing(AHazePlayerCharacter Player)
	{
		devCheck(bHasBegunPlay, "Can't stop waterski before begin play has run");

		WaterskiComps[Player].StopWaterskiing();
	}

	UFUNCTION(BlueprintPure)
	bool IsWaterskiing(AHazePlayerCharacter Player)
	{
		if(!bHasBegunPlay)
			return false;

		return WaterskiComps[Player].IsWaterskiing();
	}

	UFUNCTION()
	void AddWaterskiRopeBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		bool bWasWaterskiRopeBlocked = IsWaterskiRopeBlocked(Player);
		WaterskiComps[Player].WaterskiRopeBlockers.AddUnique(Instigator);

		if(!bWasWaterskiRopeBlocked)
		{
			WaterskiComps[Player].OnWaterskiRopeDisable();
		}
	}

	UFUNCTION()
	void ClearWaterskiRopeBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		bool bWasWaterskiRopeBlocked = IsWaterskiRopeBlocked(Player);
		WaterskiComps[Player].WaterskiRopeBlockers.RemoveSingleSwap(Instigator);
		bool bIsWaterskiRopeBlocked = IsWaterskiRopeBlocked(Player);

		if(bWasWaterskiRopeBlocked && !bIsWaterskiRopeBlocked)
		{
			WaterskiComps[Player].OnWaterskiRopeEnable();
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsWaterskiRopeBlocked(AHazePlayerCharacter Player) const
	{
		return WaterskiComps[Player].IsWaterskiRopeBlocked();
	}

	UFUNCTION()
	void BlockWaterskiBuoyancy(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		WaterskiComps[Player].BuoyancyBlockers.AddUnique(Instigator);
	}

	UFUNCTION()
	void UnblockWaterskiBuoyancy(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		WaterskiComps[Player].BuoyancyBlockers.RemoveSingleSwap(Instigator);
	}

	UFUNCTION(BlueprintPure)
	bool IsWaterskiBuoyancyBlocked(AHazePlayerCharacter Player) const
	{
		return WaterskiComps[Player].BuoyancyBlockers.Num() > 0;
	}

	UFUNCTION()
	void AddWaterskiJumpBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		Player.BlockCapabilities(PlayerMovementTags::Jump, Instigator);
		Player.BlockCapabilities(PlayerMovementTags::Dash, Instigator);
	}

	UFUNCTION()
	void RemoveWaterskiJumpBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		Player.UnblockCapabilities(PlayerMovementTags::Jump, Instigator);
		Player.UnblockCapabilities(PlayerMovementTags::Dash, Instigator);
	}

	UFUNCTION()
	void AddSpawnInWingsuitInstigator(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		WaterskiComps[Player].SpawnInWingsuitInstigators.AddUnique(Player);
	}

	UFUNCTION()
	void RemoveSpawnInWingsuitInstigator(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		WaterskiComps[Player].SpawnInWingsuitInstigators.RemoveSingleSwap(Player);
	}

	UFUNCTION(BlueprintPure)
	bool IsSpawnInWingsuitActive(AHazePlayerCharacter Player)
	{
		return WaterskiComps[Player].SpawnInWingsuitInstigators.Num() > 0;
	}
}