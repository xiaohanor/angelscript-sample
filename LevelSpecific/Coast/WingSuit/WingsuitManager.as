

event void FWingSuitLandedEventSignature(AHazePlayerCharacter Player);


UCLASS(Abstract)
class AWingsuitManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	// All the respawn spline
	UPROPERTY(EditInstanceOnly)
	TArray<TSoftObjectPtr<ASplineActor>> RespawnSplines;

	// Called when the wingsuit lands on the ground
	UPROPERTY(Category = "Events")
	FWingSuitLandedEventSignature OnWingSuitLanded;

	private TPerPlayer<AWingSuit> WingSuits;
	private AHazePlayerCharacter AHeadPlayer;
	private TPerPlayer<bool> HasStartedWingsuitSheet;
	private TPerPlayer<FSplinePosition> Internal_SplinePositions;
	private uint SplinePositionsFrameNumber;
	float NextAHeadCheckTime = 0;
	float TimeLeftToApplyHead = 0;
	AWingsuitDoubleTrainTunnelRespawnSpline DoubleTrainTunnelRespawnSpline;

	UFUNCTION(CallInEditor, Category = "Pool Settings")
	void CollectAllSplinesInLevel()
	{
	#if EDITOR
		RespawnSplines.Reset();
		auto AllSplinesRaw = Editor::GetAllEditorWorldActorsOfClass(ASplineActor);
		TArray<ASplineActor> AllSplines;
		for(auto It : AllSplinesRaw)
		{
			if(!It.RootComponent.HasTag(n"WingsuitRespawn"))
				continue;

			auto SplineActor = Cast<ASplineActor>(It);
			RespawnSplines.Add(TSoftObjectPtr<ASplineActor>(SplineActor));
		}
	#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Player: Game::GetPlayers())
		{
			auto WingSuitComp = UWingSuitPlayerComponent::Get(Player);
			#if EDITOR
			check(WingSuitComp != nullptr, "" + this + " is placed on a level where there is no wingsuit sheet added");
			#endif
			WingSuits[Player] = WingSuitComp.WingSuit;
			WingSuitComp.Manager = this;
		}

		AHeadPlayer = Game::GetMio();
		NextAHeadCheckTime = Time::GameTimeSeconds + 1;
		SetActorControlSide(AHeadPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl() && Time::GameTimeSeconds > NextAHeadCheckTime)
		{
			AHazePlayerCharacter NewAHeadPlayer = AHeadPlayer;
			const float DistanceDiff = SplinePositions[EHazePlayer::Mio].CurrentSplineDistance - SplinePositions[EHazePlayer::Zoe].CurrentSplineDistance;
			if(DistanceDiff > 0)
				NewAHeadPlayer = Game::GetMio();
			else
				NewAHeadPlayer = Game::GetZoe();

			if(NewAHeadPlayer != AHeadPlayer)
			{
				if(!AHeadPlayer.OtherPlayer.HasControl())
					TimeLeftToApplyHead -= DeltaSeconds * 10;
				else
					TimeLeftToApplyHead -= DeltaSeconds;

				if(TimeLeftToApplyHead <= 0)
					CrumbSetAHeadPlayer(NewAHeadPlayer);
			}
		}
	}

	UFUNCTION()
	void ActivateWingsuitCapabilities()
	{
		if(!HasStartedWingsuitSheet[EHazePlayer::Zoe])
			RequestComp.StartInitialSheetsAndCapabilities(Game::GetZoe(), this);

		HasStartedWingsuitSheet[EHazePlayer::Zoe] = true;

		if(!HasStartedWingsuitSheet[EHazePlayer::Mio])
			RequestComp.StartInitialSheetsAndCapabilities(Game::GetMio(), this);

		HasStartedWingsuitSheet[EHazePlayer::Mio] = true;
	}

	UFUNCTION()
	void SetFlyingOffRamp(AHazePlayerCharacter Player)
	{
		auto WingsuitPlayerComp = UWingSuitPlayerComponent::Get(Player);
		WingsuitPlayerComp.AnimData.bIsFlyingOffRamp = true;
		ActivateWingsuitCapabilitiesForPlayer(Player);
	}

	UFUNCTION()
	void ActivateWingsuitCapabilitiesForPlayer(AHazePlayerCharacter Player, UWingSuitSettings OptionalSettings = nullptr)
	{
		if(!HasStartedWingsuitSheet[Player])
			RequestComp.StartInitialSheetsAndCapabilities(Player, this);

		HasStartedWingsuitSheet[Player] = true;

		if(OptionalSettings != nullptr)
		{
			Player.ApplySettings(OptionalSettings, this, EHazeSettingsPriority::Gameplay);
		}
	}

	UFUNCTION()
	void AddWingsuitSplineRespawningBlocker(AHazePlayerCharacter Player, FInstigator Instigator, bool bDisableWingsuit = true)
	{
		auto WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		WingSuitComp.bWingSuitSplineRespawningActive.Apply(false, Instigator);
		WingSuitComp.bDisableWingsuitOnRespawnBlock.Apply(bDisableWingsuit, Instigator);
	}

	UFUNCTION()
	void ClearWingsuitSplineRespawningBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		WingSuitComp.bWingSuitSplineRespawningActive.Clear(Instigator);
		WingSuitComp.bDisableWingsuitOnRespawnBlock.Clear(Instigator);
	}

	UFUNCTION(BlueprintPure)
	bool IsWingsuitSplineRespawningBlocked(AHazePlayerCharacter Player)
	{
		auto WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		return !WingSuitComp.bWingSuitSplineRespawningActive.Get();
	}

	UFUNCTION()
	void SetShouldRespawnInWaterski(AHazePlayerCharacter Player, USceneComponent WaterskiAttachPoint)
	{
		auto WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		WingSuitComp.bShouldRespawnInWaterski = true;
		WingSuitComp.RespawnInWaterskiAttachPoint = WaterskiAttachPoint;
	}

	UFUNCTION()
	void AddWingSuitRubberbandBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		WingSuitComp.AddWingSuitRubberbandBlocker(Instigator);
	}

	UFUNCTION()
	void RemoveWingSuitRubberbandBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		WingSuitComp.RemoveWingSuitRubberbandBlocker(Instigator);
	}

	UFUNCTION(BlueprintPure)
	bool IsWingsuitActive(AHazePlayerCharacter Player) const
	{
		auto WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		return WingSuitComp.bWingsuitActive;
	}

	UFUNCTION(BlueprintPure)
	bool IsWingsuitRubberbandBlocked(AHazePlayerCharacter Player) const
	{
		auto WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		return WingSuitComp.IsWingSuitRubberbandBlocked();
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetAHeadPlayer(AHazePlayerCharacter NewAHeadPlayer)
	{
 		AHeadPlayer = NewAHeadPlayer;
		SetActorControlSide(AHeadPlayer);
		TimeLeftToApplyHead = GetRubberBandSettings(AHeadPlayer).BonusSpeedApplyDelay;
		NextAHeadCheckTime = Time::GameTimeSeconds + 1;
	}

	FWingSuitRubberBandData GetRubberBandSettings(AHazePlayerCharacter Player) const
	{
		if (Player == nullptr)
			return FWingSuitRubberBandData();
		
		auto Settings = UWingSuitSettings::GetSettings(Player);
		return Settings.RubberbandSettings;
	}

	// UFUNCTION(CrumbFunction)
	// void CrumbSetActorControlSide(AHazePlayerCharacter NewControlSidePlayer)
	// {	
 	// 	SetActorControlSide(NewControlSidePlayer);
	// }

	bool IsHead(AHazePlayerCharacter Player) const
	{
		return AHeadPlayer == Player;
	}

	FSplinePosition GetClosestSplineRespawnPosition(FVector WorldLocation) const
	{
		if(DoubleTrainTunnelRespawnSpline != nullptr)
			return DoubleTrainTunnelRespawnSpline.GetSplineRespawnPosition();

		FSplinePosition ClosestPosition;
		float ClosestDistSq = BIG_NUMBER;
	
		for(auto SplinePtr : RespawnSplines)
		{
			auto SplineActor = SplinePtr.Get();
			if(SplineActor == nullptr)
				continue;
			
			FSplinePosition SplinePos = SplineActor.Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);
			float DistSq = SplinePos.WorldLocation.DistSquared(WorldLocation);
			if(DistSq > ClosestDistSq)
				continue;

			ClosestPosition = SplinePos;
			ClosestDistSq = DistSq;
		}

		return ClosestPosition;
	}

	UFUNCTION(BlueprintPure)
	AWingSuit GetWingSuit(AHazePlayerCharacter Player) const
	{
		return WingSuits[Player];
	}

	TPerPlayer<FSplinePosition> GetSplinePositions() property
	{
		if(Time::FrameNumber != SplinePositionsFrameNumber)
		{
			Internal_SplinePositions[Game::Mio] = GetClosestSplineRespawnPosition(Game::Mio.ActorLocation);
			Internal_SplinePositions[Game::Zoe] = GetClosestSplineRespawnPosition(Game::Zoe.ActorLocation);
			SplinePositionsFrameNumber = Time::FrameNumber;
		}

		return Internal_SplinePositions;
	}
}