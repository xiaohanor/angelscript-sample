event void FASummitBreathingFireSignature();

class ASummitBreathingFire : AHazeActor
{
	UPROPERTY()
	FASummitBreathingFireSignature OnFinished;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FireRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CollisionRoot;

	UPROPERTY(DefaultComponent, Attach = CollisionRoot)
	UBoxComponent Box;

	UPROPERTY(Category = "Settings", EditAnywhere)
	bool bStartActive = true;

	UPROPERTY(Category = "Settings", EditAnywhere)
	bool bAlwaysActive;

	UPROPERTY(Category = "Settings", EditAnywhere)
    float FlameDuration = 3;

	UPROPERTY(Category = "Settings", EditAnywhere)
    float FlameInterval = 5;

	UPROPERTY(Category = "Settings", EditAnywhere)
    float DelayInterval = 0;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComp;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	bool bIsActive = false; // To be set to false so it's manually activated and not running all the time

	UPROPERTY()
	bool bFlameActive;

	float CrumbTimeStarted;

	TPerPlayer<bool> IsOverlappingFireControlSide;

	UPROPERTY(EditAnywhere)
	bool bKillFromControlSide = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		if (bAlwaysActive)
		{
			ActivateFlames();
			return;
		}

		if (HasControl())
		{
			ActionQueueComp.Idle(DelayInterval);
			if (bStartActive)
				ActionQueueComp.Event(this, n"QueueStartActivated");
			else
				ActionQueueComp.Event(this, n"QueueStartActivated");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Zoe drives the wagon, use zoe predicted crumbtrailtime
		ActionQueueComp.ScrubTo(Time::GetActorControlPredictedCrumbTrailTime(Game::Zoe) - CrumbTimeStarted);
	}

	UFUNCTION()
	private void QueueStartActivated()
	{
		CrumbQueueActivated(Time::GetActorControlPredictedCrumbTrailTime(Game::Zoe));
	}

	UFUNCTION()
	private void QueueStartDeactivated()
	{
		CrumbQueueDeactivated(Time::GetActorControlPredictedCrumbTrailTime(Game::Zoe));
	}

	UFUNCTION(CrumbFunction)
	void CrumbQueueActivated(float CrumbTime)
	{
		CrumbTimeStarted = CrumbTime;
		ActionQueueComp.Empty();
		ActionQueueComp.SetLooping(true);
		ActionQueueComp.Event(this, n"ActivateFlames");
		ActionQueueComp.Duration(FlameDuration, this, n"Burn");
		ActionQueueComp.Event(this, n"DeactivateFlames");
		ActionQueueComp.Idle(FlameInterval);

		ActionQueueComp.ScrubTo(Time::GetActorControlPredictedCrumbTrailTime(Game::Zoe) - CrumbTimeStarted);
	}

	UFUNCTION(CrumbFunction)
	void CrumbQueueDeactivated(float CrumbTime)
	{
		CrumbTimeStarted = CrumbTime;
		ActionQueueComp.Empty();
		ActionQueueComp.SetLooping(true);
		ActionQueueComp.Event(this, n"DeactivateFlames");
		ActionQueueComp.Idle(FlameInterval);
		ActionQueueComp.Event(this, n"ActivateFlames");
		ActionQueueComp.Duration(FlameDuration, this, n"Burn");

		ActionQueueComp.ScrubTo(Time::GetActorControlPredictedCrumbTrailTime(Game::Zoe) - CrumbTimeStarted);
	}


	UFUNCTION(BlueprintEvent)
	void BP_KillPlayer(AHazePlayerCharacter Player)
	{
	}

	UFUNCTION()
	private void ActivateFlames()
	{
		bFlameActive = true;
		USummitBreathingFireEventHandler::Trigger_OnFireStarted(this);
		BP_Activate();
	}
	
	UFUNCTION()
	private void Burn(float Alpha)
	{
		FHazeTraceSettings TraceSettings = Trace::InitFromPrimitiveComponent(Box);
		FOverlapResultArray Overlaps = TraceSettings.QueryOverlaps(Box.WorldLocation);
		TPerPlayer<bool> OverlappedPlayers;
		for (auto Overlap : Overlaps)
		{
			auto Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if (Player == nullptr)
				continue;

			OverlappedPlayers[Player] = true;

		}

		if (bKillFromControlSide && Network::IsGameNetworked())
		{
			if (!HasControl())
				return;

			for (auto Player : Game::Players)
			{
				if (OverlappedPlayers[Player] && !Player.IsPlayerDeadOrRespawning())
					NetKillPlayer(Player);
			}		
		}
		else
		{
			for (auto Player : Game::Players)
			{
				if (OverlappedPlayers[Player] && !Player.IsPlayerDeadOrRespawning())
					Player.KillPlayer(DeathEffect = DeathEffect);
					// Player.DamagePlayerHealth(1.0, DeathEffect = DeathEffect);
			}		
		}
	}

	UFUNCTION(NetFunction)
	void NetKillPlayer(AHazePlayerCharacter Player)
	{
		Player.KillPlayer(DeathEffect = DeathEffect);
	}

	UFUNCTION()
	private void DeactivateFlames()
	{
		bFlameActive = false;
		USummitBreathingFireEventHandler::Trigger_OnFireStopped(this);
		BP_Deactivate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate() 
    {
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_Deactivate() 
    {
		
	}

}