event void FOnAviationChanged(AHazePlayerCharacter Player);
event void FOnArenaSideChanged(ESanctuaryArenaSide NewSide);
event void FOnAviationAttack();

enum EAviationState
{
	None,
	SwoopingBack,
	Entry,
	ToAttack,
	SwoopInAttack,
	InitAttack,
	Attacking,
	AttackingSuccessCircling,
	TryExitAttack,
	Exit,
	Skydive,
};

class USanctuaryCompanionAviationPlayerComponent : UActorComponent
{
	access ReadOnly = private, * (readonly);
	
	UPROPERTY()
	float ActivateAviationDelay = 0.75;

	UPROPERTY(BlueprintReadWrite)
	FOnAviationChanged OnAviationStarted;
	UPROPERTY(BlueprintReadWrite)
	FOnAviationChanged OnAviationStopped;
	FOnArenaSideChanged OnArenaSideChanged;

	FOnAviationAttack OnAttackStart;
	FOnAviationAttack OnAttackExit;
	FOnAviationAttack OnAttackSuccess;
	FOnAviationAttack OnAttackFailed;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptRide;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptInitiateAttack;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptAttack;

	UPROPERTY(EditAnywhere)
	UBlendSpace EnterRidingAnimation;
	UPROPERTY(EditAnywhere, DisplayName = "MH Animation")
	UBlendSpace MHRidingAnimation;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<USanctuaryCompanionAviationTwoPlayerButtonMashWidget> AviationTwoPlayerButtonMashWidgetClass;
	USanctuaryCompanionAviationTwoPlayerButtonMashWidget MashWidget;

	UPROPERTY()
	UNiagaraSystem AttackingEffect;

	UPROPERTY()
	UNiagaraSystem AttackEffect;

	UPROPERTY()
	UNiagaraSystem TransformationEffect;

	UPROPERTY()
	UNiagaraSystem CompanionReadyEffect;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve MovementCurve;
	default MovementCurve.AddDefaultKey(1.0, 0.0);
	default MovementCurve.AddDefaultKey(0.0, 1.0);

	ESanctuaryArenaSide CurrentQuadrantSide;
	ESanctuaryArenaSideOctant CurrentOctantSide;

	UHazeCrumbSyncedFloatComponent SyncedKillValue;
	UHazeCrumbSyncedVector2DComponent SyncedFlyingOffsetValue;
	UHazeCrumbSyncedFloatComponent SyncedFlyingMinMaxAlphaValue;

	float AviationAllowedInputAlpha = 0.0;
	float AviationUseSplineParallelAlpha = 0.0;

	access:ReadOnly bool bControlIsAtEndOfMovementSpline = false;

	bool bIsRideReady = false;
	bool bAviationStartSnappedDirection = false;

	access:ReadOnly EAviationState AviationState;

	bool bIsAttackTutorialComplete = false;
	bool bCanInitiatingAttackingTarget = false;
	bool bHasInitiatedAttack = false;
	bool bIsInitiateAttackTutorialComplete = false;

	AHazePlayerCharacter KillFullscreenPlayer = nullptr;

	access DestinationModifyingCapability = private, USanctuaryCompanionAviationPhase1LerpDestinationToQuadCenterCapability;
	access : DestinationModifyingCapability TArray<FSanctuaryCompanionAviationDestinationData> Destinations;
	private TArray<UObject> DestinationRemoverInstigators;
	
	private AHazePlayerCharacter Player;
	private bool bIsAviationActive = false;

	ASanctuaryBossArenaManager CachedArenaManager = nullptr;

	UCompanionAviationSettings Settings;
	FVector ToAttackEndLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FHazeDevTogglePreset HydraYlvaTestPreset = FHazeDevTogglePreset(n"Auto Battle Hydra");
		HydraYlvaTestPreset.Add(AviationDevToggles::Phase1::Phase1IgnoreEssence);
		HydraYlvaTestPreset.Add(AviationDevToggles::Phase1::Phase1AutoInitateAttack);
		HydraYlvaTestPreset.Add(AviationDevToggles::Phase1::AutoPromptRiding);
		HydraYlvaTestPreset.Add(DevTogglesPlayerHealth::ZoeJesusmode);
		HydraYlvaTestPreset.Add(DevTogglesPlayerHealth::MioJesusmode);
		HydraYlvaTestPreset.Add(PlayerInputDevToggles::ButtonMash::AutoButtonMash);
		HydraYlvaTestPreset.Add(AviationDevToggles::Phase1::Phase1SlowerAttack);

		FHazeDevTogglePreset DrawAllPreset = FHazeDevTogglePreset(n"Debug Draw ALL");
		DrawAllPreset.Add(AviationDevToggles::DrawPath);
		DrawAllPreset.Add(AviationDevToggles::Phase1::Phase1DrawArenaSlices);
		DrawAllPreset.Add(AviationDevToggles::Phase1::Phase1PrintKillValues);
		DrawAllPreset.Add(SanctuaryHydraDevToggles::Drawing::PrintHydraState);
		DrawAllPreset.Add(SanctuaryHydraDevToggles::Drawing::DrawHydraCoords);
		DrawAllPreset.Add(SanctuaryHydraDevToggles::Drawing::PrintHydraTarget);

		// ---

		Player = Cast<AHazePlayerCharacter>(Owner);
		SyncedKillValue = UHazeCrumbSyncedFloatComponent::Create(Owner, n"SyncedKillValue");
		SyncedKillValue.OverrideSyncRate(EHazeCrumbSyncRate::Low);
		SyncedKillValue.SetValue(1.0);

		SyncedFlyingMinMaxAlphaValue = UHazeCrumbSyncedFloatComponent::Create(Owner, n"SyncedFlyingMinMaxAlphaValue");
		SyncedFlyingMinMaxAlphaValue.OverrideSyncRate(EHazeCrumbSyncRate::Low);
		SyncedFlyingMinMaxAlphaValue.SetValue(0.0);

		SyncedFlyingOffsetValue = UHazeCrumbSyncedVector2DComponent::Create(Owner, n"SyncedFlyingOffsetValue");
		SyncedFlyingOffsetValue.OverrideSyncRate(EHazeCrumbSyncRate::Low);
		SyncedFlyingOffsetValue.SetValue(FVector2D());

		Settings = UCompanionAviationSettings::GetSettings(Player);
		TListedActors<ASanctuaryBossArenaManager> ArenaManagers;
		for (ASanctuaryBossArenaManager ArenaManager : ArenaManagers)
		{
			OnAviationStarted.AddUFunction(ArenaManager, n"OnActivatedAviation");
			OnAviationStopped.AddUFunction(ArenaManager, n"OnDeactivatedAviation");
		}

		UpdateCurrentSide();

		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player);
		HealthComp.OnFinishDying.AddUFunction(this, n"UpdateCurrentSide"); // is this when we respawned?

		AviationDevToggles::Aviation.MakeVisible();
	}

	void SetAviationState(EAviationState NewState)
	{
		AviationState = NewState;
	}

	void SetEndOfMovementSpline()
	{
		bControlIsAtEndOfMovementSpline = true;
	}

	void ResetEndOfMovementSpline()
	{
		bControlIsAtEndOfMovementSpline = false;
	}

	EAviationState GetAviationState() const
	{
		return AviationState;
	}
	
	private ASanctuaryBossArenaManager GetArenaManager()
	{
		if (CachedArenaManager != nullptr)
			return CachedArenaManager;

		TListedActors<ASanctuaryBossArenaManager> ArenaManagers;
		for (ASanctuaryBossArenaManager ArenaManager : ArenaManagers)
		{
			CachedArenaManager = ArenaManager;
			break;
		}
		return CachedArenaManager;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TemporalLogging();
		DebugDrawArenaSlicesPlayer();
	}

	private void DebugDrawArenaSlicesPlayer()
	{
#if EDITOR
		TListedActors<ASanctuaryBossArenaManager> ArenaOrigoActor;
		bool bIsInArena = ArenaOrigoActor.Num() > 0;
		if (bIsInArena && AviationDevToggles::Phase1::Phase1DrawArenaSlices.IsEnabled() && !bIsAviationActive)
		{
			UpdateCurrentOctant();
			Debug::DrawDebugString(Player.ActorLocation, "" + CurrentQuadrantSide);
			Debug::DrawDebugString(Player.ActorLocation, "\n\n" + CurrentOctantSide);
		}
#endif
	}

	private void TemporalLogging()
	{
#if EDITOR
		TEMPORAL_LOG(Player, "Hydra Arena").Value("Quad Side", CurrentQuadrantSide);
		TEMPORAL_LOG(Player, "Hydra Arena").Value("Octant Side", CurrentOctantSide);
		TEMPORAL_LOG(Player, "Hydra Arena").Value("Aviating", bIsAviationActive);
		TEMPORAL_LOG(Player, "Hydra Arena").Value("State", AviationState);
		if (HasDestination())
		{
			const FSanctuaryCompanionAviationDestinationData& DestinationData = GetNextDestination();
			if (DestinationData.HasRuntimeSpline())
			{
				TEMPORAL_LOG(Player, "Destinations").RuntimeSpline("Destination", DestinationData.RuntimeSpline);
			}
		}

		for (int i = 0; i < Destinations.Num(); ++i)
		{
			const FSanctuaryCompanionAviationDestinationData& Destination = Destinations[i];
			FString DestinationName = "Destination " + i;
			TEMPORAL_LOG(Player, "Destinations").Value(DestinationName, Destination.AviationState);
		}

		for (int i = 0; i < DestinationRemoverInstigators.Num(); ++i)
		{
			auto DestinationRemover = DestinationRemoverInstigators[i];
			FString DestinationName = "Destination Remover" + i;
			TEMPORAL_LOG(Player, "Destinations").Value(DestinationName, DestinationRemover);
		}
		DestinationRemoverInstigators.Reset();
#endif
	}

	UFUNCTION()
	void UpdateCurrentSide() // Which quadrant in the arena are we in
	{
		ESanctuaryArenaSide PreviousSide = CurrentQuadrantSide;
		CurrentQuadrantSide = SanctuaryCompanionAviationStatics::GetArenaSideForLocation(GetArenaManager(), Player, Player.ActorLocation);
		if (PreviousSide != CurrentQuadrantSide)
			OnArenaSideChanged.Broadcast(CurrentQuadrantSide);
	}

	void UpdateCurrentOctant() // The octant is half the quadrant we're in
	{
		UpdateCurrentSide();
		TListedActors<ASanctuaryBossArenaManager> ArenaOrigoActor;
		check(ArenaOrigoActor.Num() <= 1, "More than one ASanctuaryBossArenaManager found!");
		float RightOctant = 0.0;
		for (auto OrigoActor : ArenaOrigoActor)
		{
			FVector ToLocation = Owner.ActorLocation - OrigoActor.ActorLocation;
			if (Player.IsZoe())
			{
				RightOctant = OrigoActor.ActorRotation.RightVector.DotProduct(ToLocation);
				if (CurrentQuadrantSide == ESanctuaryArenaSide::Right)
					RightOctant *= -1.0;
			}
			else
			{
				RightOctant = OrigoActor.ActorRotation.ForwardVector.DotProduct(ToLocation);
				if (CurrentQuadrantSide == ESanctuaryArenaSide::Left)
					RightOctant *= -1.0;
			}
			break;
		}
		CurrentOctantSide = RightOctant > 0.0 ? ESanctuaryArenaSideOctant::Right : ESanctuaryArenaSideOctant::Left;
	}

	float GetLeftRightOctantMultiplier()
	{
		if (CurrentOctantSide == ESanctuaryArenaSideOctant::Left)
			return -1.0;
		return 1.0;
	}

	void StartAviation()
	{
		//if (TransformationEffect != nullptr)
		//	Niagara::SpawnOneShotNiagaraSystemAttached(TransformationEffect, Player.RootComponent);
			
		bIsAviationActive = true;
		OnAviationStarted.Broadcast(Player);
		Player.ResetMovement(true);
	}

	void StopAviation()
	{
		bAviationStartSnappedDirection = false;
		UpdateCurrentSide();
		bIsAviationActive = false;
		OnAviationStopped.Broadcast(Player);
		Player.ResetMovement(true);
		if (!Player.IsPlayerDead())
			AviationState = EAviationState::Skydive;
	}

	void AddDestination(FSanctuaryCompanionAviationDestinationData Data)
	{
		if (ensure(Data.Actor != nullptr || Data.HasRuntimeSpline(), "No proper destination!"))
		{
			if (Data.Actor != nullptr)
				Data.Actor.OnDestroyed.AddUFunction(this, n"OnDestinattionActorRemoved");
			Destinations.Add(Data);
		}
		if (Destinations.Num() == 1)
			UpdateStateBools();
	}

	UFUNCTION()
	void OnDestinattionActorRemoved(AActor DestroyedActor)
	{
		for (int i = 0; i < Destinations.Num(); ++i)
		{
			if (Destinations[i].Actor == DestroyedActor)
				Destinations.RemoveAt(i);
		}
	}

	bool HasNextDestination() const
	{
		return Destinations.Num() > 1;
	}

	bool HasDestination() const
	{
		return Destinations.Num() > 0;
	}

	const FSanctuaryCompanionAviationDestinationData & GetNextDestination() const
	{
		return Destinations[0];
	}

	void RemoveCurrentDestination(bool bShouldBroadcast, UObject Instigator)
	{
		if (!ensure(Destinations.Num() > 0, "No aviation destination to remove! Was RemoveCurrentDestination called twice?"))
			return;

		DestinationRemoverInstigators.Add(Instigator);

		if (bShouldBroadcast)
			Destinations[0].OnRemoved.Broadcast();
		Destinations.RemoveAt(0);
		UpdateStateBools();
	}

	bool GetIsAviationActive() const
	{
		return bIsAviationActive;
	}
	// -----

	private void UpdateStateBools()
	{
		if (HasDestination())
		{
			const FSanctuaryCompanionAviationDestinationData& DestinationData = GetNextDestination();
			AviationState = DestinationData.AviationState;
		}
	}

	void GetAviationLanes(FSanctuaryAviationLane& OutLeft, FSanctuaryAviationLane& OutMiddle, FSanctuaryAviationLane& OutRight)
	{
		if (HasDestination())
		{
			const FSanctuaryCompanionAviationDestinationData& DestinationData = GetNextDestination();
			FVector SplineDirection = (DestinationData.RuntimeSpline.Points[1] - DestinationData.RuntimeSpline.Points[0]).GetSafeNormal();
			FVector SplineRightDirection = FVector::UpVector.CrossProduct(SplineDirection).GetSafeNormal();
			
			OutMiddle.StartLocation = DestinationData.RuntimeSpline.Points[0];
			OutMiddle.EndLocation = DestinationData.RuntimeSpline.Points[1];

			OutLeft.StartLocation = DestinationData.RuntimeSpline.Points[0] - SplineRightDirection * Settings.SidewaysMovementDistanceMax;
			OutLeft.EndLocation = DestinationData.RuntimeSpline.Points[1] - SplineRightDirection * Settings.SidewaysMovementDistanceMax;

			OutRight.StartLocation = DestinationData.RuntimeSpline.Points[0] + SplineRightDirection * Settings.SidewaysMovementDistanceMax;
			OutRight.EndLocation = DestinationData.RuntimeSpline.Points[1] + SplineRightDirection * Settings.SidewaysMovementDistanceMax;
		}
	}

	void KillFail()
	{
		OnAttackFailed.Broadcast();
		USanctuaryCompanionAviationPlayerEventHandler::Trigger_AttackFail(Player);
	}

	void KillSuccess()
	{
		OnAttackSuccess.Broadcast();
		USanctuaryCompanionAviationPlayerEventHandler::Trigger_AttackSuccess(Player);
	}
};

UFUNCTION(BlueprintCallable)
bool SanctuaryAreBothPlayersAviationActive()
{
	for(auto Player : Game::Players)
	{
		auto AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		if(AviationComp == nullptr)
			return false;

		if(!AviationComp.GetIsAviationActive())
			return false;
	}

	return true;
}