
class AWingSuitBlockRespawnZone : AActor
{	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent TriggerEnterZone;
	default TriggerEnterZone.Shape = FHazeShapeSettings::MakeBox(FVector(500, 500, 500));
	
	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent TriggerExitZone;
	default TriggerExitZone.Shape = FHazeShapeSettings::MakeBox(FVector(500, 500, 500));
	default TriggerExitZone.ShapeColor = FLinearColor::Red * 0.8;

	/* If true respawn will be blocked for the player if inside the zone, if any player is inside the zone a game over will be triggered if both players die */
	UPROPERTY(EditAnywhere)
	bool bBlockRespawnForOtherPlayerWithinZone = true;

	/* If true, player (if entered block respawn zone) will respawn not in wingsuit */
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "!bBlockRespawnForOtherPlayerWithinZone", EditConditionHides))
	bool bExitWingsuit = false;

	TPerPlayer<bool> bHasBlockedPlayer;
	TPerPlayer<bool> bHasLeftTheZone;
	AWingsuitManager WingsuitManager;
	UPlayerHealthComponent MioHealthComp;
	UPlayerHealthComponent ZoeHealthComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<AWingsuitManager> ListedManager;
		WingsuitManager = ListedManager.GetSingle();
		devCheck(WingsuitManager != nullptr, "Wingsuit manager is missing");
		TriggerEnterZone.OnPlayerEnter.AddUFunction(this, n"OnPlayerTriggerEnter");
		TriggerExitZone.OnPlayerLeave.AddUFunction(this, n"OnPlayerTriggerLeave");

		MioHealthComp = UPlayerHealthComponent::Get(Game::Mio);
		ZoeHealthComp = UPlayerHealthComponent::Get(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bBlockRespawnForOtherPlayerWithinZone)
			return;

		if(!bHasBlockedPlayer[Game::Mio] && !bHasBlockedPlayer[Game::Zoe])
			return;

		if(MioHealthComp.bIsDead && ZoeHealthComp.bIsDead)
		{
			MioHealthComp.TriggerGameOver();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerTriggerEnter(AHazePlayerCharacter Player)
	{
		if(!IsZoneCompleted())
		{
			bHasBlockedPlayer[Player] = true;
			auto WingSuitComp = UWingSuitPlayerComponent::Get(Player);
			WingSuitComp.Manager.AddWingsuitSplineRespawningBlocker(Player, this, bExitWingsuit);

			if(bBlockRespawnForOtherPlayerWithinZone)
				Player.BlockCapabilities(n"Respawn", this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerTriggerLeave(AHazePlayerCharacter Player)
	{
		// this will make us not block the players respawn any longer
		bHasLeftTheZone[Player] = true;

		for(auto PlayerIt : Game::GetPlayers())
		{
			if(bHasBlockedPlayer[PlayerIt])
			{
				bHasBlockedPlayer[PlayerIt] = false;
				auto WingSuitComp = UWingSuitPlayerComponent::Get(PlayerIt);
				WingSuitComp.Manager.ClearWingsuitSplineRespawningBlocker(PlayerIt, this);

				if(bBlockRespawnForOtherPlayerWithinZone)
					PlayerIt.UnblockCapabilities(n"Respawn", this);
			}
		}
	}

	private bool IsZoneCompleted() const
	{
		return bHasLeftTheZone[EHazePlayer::Mio] || bHasLeftTheZone[EHazePlayer::Zoe];
	}
}

