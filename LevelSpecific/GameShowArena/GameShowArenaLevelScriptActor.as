enum EBombTossChallenges
{
	BombToss01,
	BombToss02,
	BombToss03,
	BombToss04,
	BombToss05,
	BombToss06,
	BombToss07,
	BombToss08,
	BombToss09,
	BombTossStart,
	BombTossTutorial,
	MAX UMETA(Hidden)
}

struct FBombTossChallengeActors
{
	UPROPERTY()
	TArray<AHazeActor> Actors;
}

delegate void FGameShowArenaChallengeTriggerTimeoutEvent();

class AGameShowArenaLevelScriptActor : AHazeLevelScriptActor
{
	UPROPERTY()
	TArray<AGameShowArenaTutorialMonitor> TutorialMonitors;

	int BombCatchCounter = 0;
	int BombCatchDisplayCounter = 0;
	int TutorialCatchTarget = 5;

	//Level Conditions
	UPROPERTY()
	bool bZoeOnTrigger01 = false;
	UPROPERTY()
	bool bTutorialStartedFromNaturalProgression = false;
	UPROPERTY()
	bool bBombToss01StartedFromNaturalProgression = false;
	UPROPERTY()
	bool bBombToss02StartedFromNaturalProgression = false;
	UPROPERTY()
	bool bBombToss03StartedFromNaturalProgression = false;
	UPROPERTY()
	bool bBombToss04StartedFromNaturalProgression = false;
	UPROPERTY()
	bool bBombToss05StartedFromNaturalProgression = false;
	UPROPERTY()
	bool bBombTossEndingStartedFromNaturalProgression = false;
	UPROPERTY()
	bool bRaisedInitialPlatformsInSeq = false;

	UGameShowArenaBombTossPlayerComponent MioBombTossPlayerComponent;
	UGameShowArenaBombTossPlayerComponent ZoeBombTossPlayerComponent;

	//Only used for dev functions!!
	UPROPERTY()
	EBombTossChallenges CurrentChallenge;

	UPROPERTY()
	TArray<ARespawnPoint> BombTossRespawnPoints;

	UPROPERTY()
	TArray<AGameShowArenaSpotlight> GameShowSpotlights;

	UPROPERTY(BlueprintReadOnly)
	TArray<FBombTossChallengeActors> GameShowArenaChallengeActors;
	default GameShowArenaChallengeActors.SetNum(EBombTossChallenges::MAX);

	FGameShowArenaChallengeTriggerTimeoutEvent OnNextChallengeTriggerTimedOut;
	FTimerHandle NextChallengeTriggerTimerHandle;

	UFUNCTION(BlueprintCallable)
	void SetCurrentChallenge(EBombTossChallenges Challenge)
	{
		CurrentChallenge = Challenge;
		GameShowArena::GetGameShowArenaPlatformManager().SetCurrentChallenge(Challenge);
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void StartMovingPlatforms(FString LayoutName)
	{
		GameShowArena::GetGameShowArenaPlatformManager().StartMovingPlatforms(LayoutName);
	}

	UFUNCTION(BlueprintCallable)
	void SnapPlatformsToPosition(FString LayoutName)
	{
		GameShowArena::GetGameShowArenaPlatformManager().SnapPlatformsToPosition(LayoutName);
	}

	UFUNCTION()
	void RemoveBombFromPlay(AGameShowArenaBomb Bomb)
	{
		if (!HasControl())
			return;

		CrumbRemoveBombFromPlay(Bomb);
	}

	UFUNCTION(CrumbFunction)
	void CrumbRemoveBombFromPlay(AGameShowArenaBomb Bomb)
	{
		for (auto Player : Game::GetPlayers())
		{
			auto PlayerComp = UGameShowArenaBombTossPlayerComponent::Get(Player);
			if (PlayerComp.CurrentBomb == Bomb)
				PlayerComp.RemoveBomb();
		}

		Bomb.ApplyState(EGameShowArenaBombState::Disposed, this, EInstigatePriority::Override);
		Bomb.AddActorDisable(this);
	}

	UFUNCTION(BlueprintCallable)
	void EnableLaserWallForChallenge(EBombTossChallenges BombTossChallenge)
	{
		// Laser walls are activated by default when you call TriggerNextChallenge
		TListedActors<AGameShowArenaDynamicObstacleBase> Obstacles;
		for (AGameShowArenaDynamicObstacleBase Obstacle : Obstacles)
		{
			AGameShowArenaLaserWall LaserWall = Cast<AGameShowArenaLaserWall>(Obstacle);
			if (LaserWall != nullptr)
			{
				if (LaserWall.BombTossChallenge == BombTossChallenge)
					LaserWall.ClearAllDisables();
				else
					LaserWall.AddActorDisable(this);
			}
		}
	}

	UFUNCTION()
	void ActivateAllDynamicObstaclesForChallenge(EBombTossChallenges BombTossChallenge, bool bDisableUnusedObstacles = true)
	{
		int ChallengeFlag = 1 << uint(BombTossChallenge);
		TListedActors<AGameShowArenaDynamicObstacleBase> DynamicObstacles;
		for (auto Obstacle : DynamicObstacles)
		{
			if (Obstacle.BombTossChallengeUses & ChallengeFlag != 0)
				Obstacle.ClearAllDisables();
			else if (bDisableUnusedObstacles)
				Obstacle.AddActorDisable(this);
		}
		TListedActors<AGameShowArenaDisplayDecalSplineFollow> SplineFollowDecals;
		for (auto Decal : SplineFollowDecals)
		{
			if (Decal.BombTossChallengeUses & ChallengeFlag != 0)
				Decal.ClearAllDisables();
			else if (bDisableUnusedObstacles)
				Decal.AddActorDisable(this);
		}
	}

	/**
	 * Activates all actors found in ChallengeActors Array for the specific Challenge index.
	 * @param `BombTossChallenge` - The index for the actors to activate.
	 * @param `bDisableOtherChallengeActors` - Whether to enable or disable the other actors not identified by index.
	 */
	UFUNCTION()
	void ActivateAllActorsForChallenge(EBombTossChallenges BombTossChallenge, bool bDisableOtherChallengeActors = true)
	{
		if (bDisableOtherChallengeActors)
		{
			for (int i = 0; i < GameShowArenaChallengeActors.Num(); i++)
			{
				bool bShouldDisable = i != int(BombTossChallenge);
				for (auto Actor : GameShowArenaChallengeActors[i].Actors)
				{
					if (bShouldDisable)
						Actor.AddActorDisable(this);
					else
						Actor.ClearAllDisables();
				}
			}
		}
		else
		{
			for (auto Actor : GameShowArenaChallengeActors[int(BombTossChallenge)].Actors)
			{
				Actor.AddActorDisable(this);
			}
		}
	}

	UFUNCTION()
	void DeactivateAllActorsForChallenge(EBombTossChallenges BombTossChallenge)
	{
		for (auto Actor : GameShowArenaChallengeActors[int(BombTossChallenge)].Actors)
		{
			Actor.ClearAllDisables();
		}
	}

	UFUNCTION()
	void DeactivateAllDynamicObstaclesForChallenge(EBombTossChallenges BombTossChallenge)
	{
		int ChallengeFlag = 1 << uint(BombTossChallenge);

		TListedActors<AGameShowArenaDynamicObstacleBase> DynamicObstacles;
		for (auto Obstacle : DynamicObstacles)
		{
			if (Obstacle.BombTossChallengeUses & ChallengeFlag != 0)
				Obstacle.AddActorDisable(this);
		}

		TListedActors<AGameShowArenaDisplayDecalSplineFollow> SplineFollowDecals;
		for (auto Decal : SplineFollowDecals)
		{
			if (Decal.BombTossChallengeUses & ChallengeFlag != 0)
				Decal.AddActorDisable(this);
		}
	}

	UFUNCTION()
	void DeactivateAllDynamicObstacles()
	{
		TListedActors<AGameShowArenaDynamicObstacleBase> DynamicObstacles;
		for (auto Obstacle : DynamicObstacles)
		{
			Obstacle.AddActorDisable(this);
		}

		TListedActors<AGameShowArenaDisplayDecalSplineFollow> SplineFollowDecals;
		for (auto Decal : SplineFollowDecals)
		{
			Decal.AddActorDisable(this);
		}
	}

	UFUNCTION()
	void SetExplodeDurationOnBombs(float Duration)
	{
		TListedActors<AGameShowArenaBomb> Bombs;
		for (auto Bomb : Bombs)
		{
			Bomb.SetExplodeTimerDuration(Duration);
		}
	}

	UFUNCTION(Meta = (UseExecPins))
	void TriggerNextChallengeV2(EBombTossChallenges ChallengeToTrigger, FString LayoutName, float PlatformMoveDuration, float BombExplodeDuration = 7, FGameShowArenaChallengeTriggerTimeoutEvent OnTimedOut = FGameShowArenaChallengeTriggerTimeoutEvent(), bool bShouldPlaySeq = true, AHazeLevelSequenceActor SeqToPlay = nullptr, bool bOverrideSpawns = true)
	{
		CurrentChallenge = ChallengeToTrigger;
		GameShowArena::GetGameShowArenaPlatformManager().SetCurrentChallenge(ChallengeToTrigger);

		if (bShouldPlaySeq)
			PlayAnnouncerSequence(ChallengeToTrigger);

		SnapPlatformsToPosition(LayoutName);

		if (bOverrideSpawns)
		{
			ARespawnPoint Respawn = BombTossRespawnPoints[ChallengeToTrigger];
			for (auto Player : Game::GetPlayers())
			{
				Player.TeleportToRespawnPoint(Respawn, this);
				Player.ResetStickyRespawnPoints();
				Player.SetStickyRespawnPoint(Respawn);
				Player.SnapCameraBehindPlayer();
			}
		}

		EnableLaserWallForChallenge(ChallengeToTrigger);
		SetExplodeDurationOnBombs(BombExplodeDuration);

		if (bShouldPlaySeq)
		{
			SeqToPlay.OnSequenceSkippedEvent.AddUFunction(this, n"SequencerSkipped");

			OnNextChallengeTriggerTimedOut = OnTimedOut;
			NextChallengeTriggerTimerHandle = Timer::SetTimer(this, n"HandleChallengeTriggerTimeOut", SeqToPlay.DurationAsSeconds);
		}
	}

	UFUNCTION()
	private void SequencerSkipped(float32 PositionWhenSkipped)
	{
		NextChallengeTriggerTimerHandle.ClearTimerAndInvalidateHandle();
		HandleChallengeTriggerTimeOut();
	}

	UFUNCTION()
	void HandleChallengeTriggerTimeOut()
	{
		OnNextChallengeTriggerTimedOut.ExecuteIfBound();
	}

	UFUNCTION(BlueprintEvent)
	void PlayAnnouncerSequence(EBombTossChallenges ChallengeToTrigger)
	{
	}

	UFUNCTION()
	void ActivateBombCatchCounter()
	{
		MioBombTossPlayerComponent = UGameShowArenaBombTossPlayerComponent::Get(Game::Mio);
		MioBombTossPlayerComponent.OnPlayerCaughtBomb.AddUFunction(this, n"OnPlayerCaughtBomb");
		UPlayerHealthComponent::Get(Game::Mio).OnStartDying.AddUFunction(this, n"OnPlayerStartedDying");

		ZoeBombTossPlayerComponent = UGameShowArenaBombTossPlayerComponent::Get(Game::Zoe);
		ZoeBombTossPlayerComponent.OnPlayerCaughtBomb.AddUFunction(this, n"OnPlayerCaughtBomb");
		UPlayerHealthComponent::Get(Game::Zoe).OnStartDying.AddUFunction(this, n"OnPlayerStartedDying");

		ResetBombCounter();
	}

	UFUNCTION()
	private void OnPlayerStartedDying()
	{
		ResetBombCounter();
	}

	void DeactivateBombCatchCounter()
	{
		MioBombTossPlayerComponent.OnPlayerCaughtBomb.Unbind(this, n"OnPlayerCaughtBomb");
		ZoeBombTossPlayerComponent.OnPlayerCaughtBomb.Unbind(this, n"OnPlayerCaughtBomb");
		UPlayerHealthComponent::Get(Game::Mio).OnStartDying.Unbind(this, n"OnPlayerStartedDying");
		UPlayerHealthComponent::Get(Game::Zoe).OnStartDying.Unbind(this, n"OnPlayerStartedDying");
	}

	UFUNCTION()
	private void OnPlayerCaughtBomb(AHazePlayerCharacter Player, AGameShowArenaBomb Bomb)
	{
		if (HasControl())
		{
			BombCatchCounter++;
			CrumbUpdateCatchCount(BombCatchCounter);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbUpdateCatchCount(int Count)
	{
		if(Count == 1)
			BP_PlayerCaughtBombFirstTimeTutorial();

		BombCatchCounter = Count;
		if (Count > 0)
			BombCatchDisplayCounter = BombCatchCounter - 1;
		else
			BombCatchDisplayCounter = 0;

		UpdateMonitors(BombCatchDisplayCounter);

		if (BombCatchCounter >= TutorialCatchTarget)
		{
			TutorialCatchCompleted();
			DeactivateBombCatchCounter();
			BP_RemoveTutorialPrompt();
		}
	}

	// Activates 2D space Tutorial prompt
	UFUNCTION(BlueprintEvent)
	void BP_PlayerCaughtBombFirstTimeTutorial()
	{}

	void UpdateMonitors(int Catches)
	{
		for (auto Monitor : TutorialMonitors)
		{
			Monitor.UpdateCatchCounter(Catches);
		}
	}

	void ResetBombCounter()
	{
		BP_RemoveTutorialPrompt();

		if (HasControl())
		{
			CrumbUpdateCatchCount(0);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_RemoveTutorialPrompt()
	{}

	UFUNCTION(BlueprintEvent)
	void TutorialCatchCompleted()
	{
	}

	// Only used for dev function!
	UFUNCTION(DevFunction)
	void DevTriggerNextChallenge()
	{
		switch(CurrentChallenge)
		{
			//Yup, the order is fuuuucked. 
			case EBombTossChallenges::BombTossTutorial:
				BP_DevTriggerBombToss01();
				break;
			case EBombTossChallenges::BombToss01:
				BP_DevTriggerBombToss02();
				break;
			case EBombTossChallenges::BombToss05:
				BP_DevTriggerBombToss03();
				break;
			case EBombTossChallenges::BombToss03:
				BP_DevTriggerBombToss04();
				break;
			case EBombTossChallenges::BombToss06:
				BP_DevTriggerBombToss05();
				break;
			case EBombTossChallenges::BombToss07:
				BP_DevTriggerBombTossEnding();
				break;
			default:
				break;
		}
	}

	// Only used for dev function!
	UFUNCTION(BlueprintEvent)
	void BP_DevTriggerBombToss01()
	{}
	UFUNCTION(BlueprintEvent)
	void BP_DevTriggerBombToss02()
	{}
	UFUNCTION(BlueprintEvent)
	void BP_DevTriggerBombToss03()
	{}
	UFUNCTION(BlueprintEvent)
	void BP_DevTriggerBombToss04()
	{}
	UFUNCTION(BlueprintEvent)
	void BP_DevTriggerBombToss05()
	{}
	UFUNCTION(BlueprintEvent)
	void BP_DevTriggerBombTossEnding()
	{}

}