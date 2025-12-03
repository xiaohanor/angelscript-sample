class ASanctuaryGhostTutorial : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ASanctuaryGhost TutorialGhost;

	UPROPERTY(EditAnywhere)
	ACapabilitySheetVolume TutorialGhostSheet;

	UPROPERTY(EditAnywhere)
	ASanctuaryLightBirdSocket Socket;

	UPROPERTY(EditAnywhere)
	APlayerTrigger GhostTutorialTrigger;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	bool bRecallBird = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TutorialGhost.OnUnSpawn.AddUFunction(this, n"HandleUnspawn");
		TutorialGhostSheet.AddActorDisable(this);
		TutorialGhost.OnDie.AddUFunction(this, n"HandleGhostKilled");
		GhostTutorialTrigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
		TutorialGhost.OnReveal.AddUFunction(this, n"HandelReveal");
	}



	UFUNCTION()
	private void HandleUnspawn()
	{
		TutorialFinished();
	}

	UFUNCTION()
	private void HandleGhostKilled()
	{
		TutorialFinished();
	}

	UFUNCTION()
	private void HandelReveal()
	{
		RecallBird();
		Socket.LightBirdTargetComp.SetUsableByPlayers(EHazeSelectPlayer::None);
		TutorialGhostSheet.RemoveActorDisable(this);

		FHazePointOfInterestFocusTargetInfo POI;
		POI.SetFocusToWorldLocation(TutorialGhost.GetActorLocation() + FVector::UpVector * 1000.0);
		FApplyPointOfInterestSettings POISettings;
		POISettings.Duration = 0.5;
		
		
		Game::Mio.ApplyPointOfInterest(this, POI, POISettings, POISettings.Duration);
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		if(Player==Game::Mio)
		{
			TutorialGhost.Activate();

	
		}
	}


	void RecallBird()
	{
		
			auto UserComp = ULightBirdUserComponent::Get(Game::Mio);
			UserComp.Hover();
			UserComp.Companion.CompanionComp.State = ELightBirdCompanionState::Obstructed;
			bRecallBird=true;
		
		
	}

	void TutorialFinished()
	{
		Socket.LightBirdTargetComp.SetUsableByPlayers(EHazeSelectPlayer::Mio);
		TutorialGhostSheet.AddActorDisable(this);
		DestroyActor();
	}
};