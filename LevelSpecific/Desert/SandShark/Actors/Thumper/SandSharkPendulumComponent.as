event void FOnSandSharkPlayerPendulumEnter(AHazePlayerCharacter Player);
event void FOnSandSharkPlayerPendulumExit(AHazePlayerCharacter Player);
event void FOnSandSharkPlayerPendulumSuccess(AHazePlayerCharacter Player);
event void FOnSandSharkPlayerPendulumComplete(AHazePlayerCharacter Player);
event void FOnSandSharkPlayerPendulumFail(AHazePlayerCharacter Player);

enum ESandSharkPendulumState
{
	None,
	Active,
	Failed,
	Completed
}

enum ESandSharkPendulumActiveDangerZoneState
{
	None,
	Left,
	Right
}

struct FSandSharkPendulumSyncParams
{
	float PendulumPosition;
	float Phase;
	float ActiveDuration;
}

enum ESandSharkPendulumAnimationState
{
	Enter,
	Mh,
	Thump,
	Exit
}

struct FSandSharkPendulumAnimationData
{
	UPROPERTY()
	ESandSharkPendulumAnimationState AnimState;

	UPROPERTY()
	bool bIsLeftSideThumper;
}

struct FSandSharkPendulumComponentData
{
	ESandSharkPendulumState State;
	ESandSharkPendulumActiveDangerZoneState ActiveDangerZoneState;

	float ActivationTime = 0;
	float PrevPendulumPosition = 0.0;
	float PendulumPosition = 0.0;
	float ActiveDuration = 0;

	float CurrentDirection = 0;
	float FailDirection = 0;
	float LastSuccessTime = 0;
	float TimeWhenFailed = 0;
	float TimeWhenCompleted = 0;
	float TimeWhenLastValidInput = 0;
	uint CurrentSuccessCount = 0;
}

class USandSharkPendulumComponent : USceneComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = "Widget")
	TSubclassOf<USandSharkThumperPendulumWidget> WidgetClass;

	// Time it takes for a left and right swing
	UPROPERTY(Category = "Pendulum")
	float Period = 4;

	UPROPERTY(Category = "Pendulum")
	float SuccessFraction = 0.35;

	UPROPERTY(Category = "Pendulum")
	float SuccessBufferFraction = 0.15;

	UPROPERTY(Category = "Pendulum")
	float MaxAngle = 130;

	UPROPERTY(Category = "Pendulum")
	FOnSandSharkPlayerPendulumEnter OnEnter;

	UPROPERTY(Category = "Pendulum")
	FOnSandSharkPlayerPendulumExit OnExit;

	UPROPERTY(Category = "Pendulum")
	FOnSandSharkPlayerPendulumSuccess OnSuccess;

	UPROPERTY(Category = "Pendulum")
	FOnSandSharkPlayerPendulumFail OnFail;

	UPROPERTY(Category = "Pendulum")
	FOnSandSharkPlayerPendulumComplete OnComplete;

	USceneComponent WidgetAttachComponent;

	// Gameplay variables
	USandSharkThumperPendulumWidget Widget;
	AHazePlayerCharacter InteractingPlayer;

	bool bShouldFailOnNoInput = false;
	bool bIsCompletable = true;

	const float SuccessFractionGrowthTime = 0.45;
	const float FailRemovalTime = 0.5;
	const float CompletedRemovalTime = 0.5;
	const float CompleteRemovalTime = 0.5;
	const float DisableDuration = 0.4;

	const uint NrOfSuccessForComplete = 4;

	UHazeCrumbSyncedFloatComponent SyncedPendulumPhase;

	FHazeAcceleratedFloat AccPhase;

	UDesertPlayerPendulumComponent ThumpingPlayerComp;

	bool bDebugAutoThump = false;

	// Storing all non-const non-ref variables in a struct to make resetting cleaner
	FSandSharkPendulumComponentData Data;

	float LastSuccessAlpha;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SyncedPendulumPhase = UHazeCrumbSyncedFloatComponent::GetOrCreate(Owner, n"SyncedPendulumPhase");
		SyncedPendulumPhase.OverrideSyncRate(EHazeCrumbSyncRate::Low);
	}

	void UpdatePendulumPosition()
	{
		Data.PendulumPosition = Math::Sin((TWO_PI / Period) * Data.ActiveDuration + AccPhase.Value - (PI / Period));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// float ActiveTime = Time::GetGameTimeSince(ActivationTime);
		AccPhase.AccelerateTo(SyncedPendulumPhase.Value, 0.1, DeltaTime);
		Data.ActiveDuration += DeltaTime;
#if EDITOR
		TEMPORAL_LOG(this).Value("State", Data.State);
#endif
		switch (Data.State)
		{
			case ESandSharkPendulumState::None:
				break;
			case ESandSharkPendulumState::Active:
				HandleActiveState();
				break;
			case ESandSharkPendulumState::Failed:
				if (Time::PredictedGlobalCrumbTrailTime - Data.TimeWhenFailed > FailRemovalTime)
					StopPendulum(InteractingPlayer);
				break;
			case ESandSharkPendulumState::Completed:
				if (Time::PredictedGlobalCrumbTrailTime - Data.TimeWhenCompleted > CompletedRemovalTime)
					StopPendulum(InteractingPlayer);
				break;
		}
	}

	void HandleActiveState()
	{
		Data.PrevPendulumPosition = Data.PendulumPosition;
		UpdatePendulumPosition();

		Data.CurrentDirection = Math::Sign(Data.PendulumPosition - Data.PrevPendulumPosition);
		bool bIsInFailZone = false;
		if (Data.FailDirection < 0)
			bIsInFailZone = Math::IsWithinInclusive(Data.PendulumPosition, -1, -SuccessFraction);
		else if (Data.FailDirection > 0)
			bIsInFailZone = Math::IsWithinInclusive(Data.PendulumPosition, SuccessFraction, 1);

		if (HasControl())
		{
			if (bDebugAutoThump)
			{
				if (IsInSuccessZone())
					DoPlayerPress(InteractingPlayer);
			}
			if (Data.CurrentDirection == Data.FailDirection && bIsInFailZone)
				CrumbHandleFail(InteractingPlayer);
		}

		if (Time::PredictedGlobalCrumbTrailTime - Data.LastSuccessTime < DisableDuration)
			Widget.bIsTemporarilyDisabled = true;
		else
			Widget.bIsTemporarilyDisabled = false;

		if (Data.FailDirection < -MIN_flt)
			Data.ActiveDangerZoneState = ESandSharkPendulumActiveDangerZoneState::Left;
		else if (Data.FailDirection > MIN_flt)
			Data.ActiveDangerZoneState = ESandSharkPendulumActiveDangerZoneState::Right;
		else
			Data.ActiveDangerZoneState = ESandSharkPendulumActiveDangerZoneState::None;

		Widget.PendulumPosition = Data.PendulumPosition;
		Widget.MaxAngle = MaxAngle;
		Widget.CurrentPendulumAngle = -Data.PendulumPosition * MaxAngle;
		Widget.bHasInteractingPlayer = InteractingPlayer != nullptr;
		Widget.ActiveDangerZoneState = Data.ActiveDangerZoneState;
	}

	float GetRemainingSuccessAlpha()
	{
		float Alpha;
		if (Data.FailDirection < 0)
		{
			Alpha = Math::Saturate(Math::GetMappedRangeValueClamped(
				FVector2D(-SuccessFraction, SuccessFraction),
				FVector2D(0, 1),
				Data.PendulumPosition));
		}
		else
		{
			Alpha = Math::Saturate(Math::GetMappedRangeValueClamped(
				FVector2D(-SuccessFraction, SuccessFraction),
				FVector2D(1, 0),
				Data.PendulumPosition));
		}

		return Alpha;
	}

	bool IsInSuccessZone()
	{
		return Math::Abs(Data.PendulumPosition) <= SuccessFraction;
	}

	bool IsInRelevantBufferZone()
	{
		// get the bufferzone depending on which direction we have
		if (Data.CurrentDirection < 0)
			return Math::IsWithinInclusive(Data.PendulumPosition, SuccessFraction, SuccessFraction + SuccessBufferFraction);
		else
			return Math::IsWithinInclusive(Data.PendulumPosition, -(SuccessFraction + SuccessBufferFraction), -SuccessFraction);
	}

	bool IsInFailZone()
	{
		if (Data.FailDirection < 0)
			return Math::IsWithinInclusive(Data.PendulumPosition, -1, -SuccessFraction);
		else if (Data.FailDirection > 0)
			return Math::IsWithinInclusive(Data.PendulumPosition, SuccessFraction, 1);

		return false;
	}

	UFUNCTION(BlueprintCallable, Category = "Gameplay|Pendulum")
	void StartPendulum(AHazePlayerCharacter Player)
	{
		InteractingPlayer = Player;

		ThumpingPlayerComp = UDesertPlayerPendulumComponent::GetOrCreate(Player);
		ThumpingPlayerComp.CurrentPendulum = this;

		Data = FSandSharkPendulumComponentData();

		Data.State = ESandSharkPendulumState::Active;
		Data.ActivationTime = Time::PredictedGlobalCrumbTrailTime;
		SyncedPendulumPhase.SetValue(0);
		AccPhase.SnapTo(0);
		Widget = Player.AddWidget(WidgetClass);
		Widget.SetWidgetShowInFullscreen(true);
		Network::SetActorControlSide(Owner, Player);

		float SuccessCircularFrac = SuccessFraction * (MaxAngle * 2) / 360;
		float BufferCircularFrac = (SuccessBufferFraction + SuccessFraction) * (MaxAngle * 2) / 360;
		Widget.SuccessFraction = SuccessCircularFrac;
		Widget.BufferSuccessFraction = BufferCircularFrac;

		if (WidgetAttachComponent == nullptr)
			Widget.AttachWidgetToComponent(this);
		else
			Widget.AttachWidgetToComponent(WidgetAttachComponent);

		SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintCallable, Category = "Gameplay|Pendulum")
	void StopPendulum(AHazePlayerCharacter Player)
	{
		if (HasControl())
			CrumbStopPendulum(Player);
	}
	UFUNCTION(CrumbFunction)
	void CrumbStopPendulum(AHazePlayerCharacter Player)
	{
		if (ThumpingPlayerComp != nullptr)
			ThumpingPlayerComp.CurrentPendulum = nullptr;

		if (Widget != nullptr)
		{
			Player.RemoveWidget(Widget);
			Widget = nullptr;
		}

		Data.State = ESandSharkPendulumState::None;
		SetComponentTickEnabled(false);
		InteractingPlayer = nullptr;
	}

	UFUNCTION(CrumbFunction)
	void CrumbHandleSuccess(AHazePlayerCharacter Player)
	{
		OnSuccess.Broadcast(Player);
		if (Widget != nullptr)
			Widget.BP_PendulumSuccess();

		Data.CurrentSuccessCount++;
		Data.LastSuccessTime = Time::PredictedGlobalCrumbTrailTime;

		if (ThumpingPlayerComp != nullptr)
			ThumpingPlayerComp.AnimData.AnimState = ESandSharkPendulumAnimationState::Thump;

		Timer::SetTimer(this, n"ResetThumpAnim", 0.3);
		LastSuccessAlpha = GetRemainingSuccessAlpha();
	}

	UFUNCTION()
	private void ResetThumpAnim()
	{
		if (ThumpingPlayerComp != nullptr)
			ThumpingPlayerComp.AnimData.AnimState = ESandSharkPendulumAnimationState::Mh;
	}

	UFUNCTION(CrumbFunction)
	void CrumbHandleComplete(AHazePlayerCharacter Player)
	{
		Data.State = ESandSharkPendulumState::Completed;
		Data.TimeWhenCompleted = Time::PredictedGlobalCrumbTrailTime;
		OnComplete.Broadcast(Player);
		if (Widget != nullptr)
			Widget.BP_PendulumCompleted();
	}

	UFUNCTION(CrumbFunction)
	void CrumbHandleFail(AHazePlayerCharacter Player)
	{
		Data.State = ESandSharkPendulumState::Failed;
		Data.TimeWhenFailed = Time::PredictedGlobalCrumbTrailTime;
		OnFail.Broadcast(Player);
		if (Widget != nullptr)
			Widget.BP_PendulumFail();
		if (ThumpingPlayerComp != nullptr)
			ThumpingPlayerComp.AnimData.AnimState = ESandSharkPendulumAnimationState::Exit;
	}

	UFUNCTION(BlueprintCallable, Category = "Gameplay|Pendulum")
	void DoPlayerPress(AHazePlayerCharacter Player)
	{
		if (Data.State != ESandSharkPendulumState::Active)
			return;

		if (Widget.bIsTemporarilyDisabled)
			return;

		// If we press too quickly do nothing
		if (Time::GetGameTimeSince(Data.TimeWhenLastValidInput) < DisableDuration)
		{
			return;
		}
		Data.TimeWhenLastValidInput = Time::GameTimeSeconds;

		if (IsInSuccessZone())
		{
			if (HasControl())
			{
				CrumbHandleSuccess(Player);
				if (bIsCompletable && Data.CurrentSuccessCount == NrOfSuccessForComplete)
					CrumbHandleComplete(Player);
			}
		}
		else if (IsInRelevantBufferZone())
		{
			if (HasControl())
			{
				float PhaseOffset = (Math::Abs(Data.PendulumPosition) - SuccessFraction) * 0.5 * PI;
				SyncedPendulumPhase.SetValue(SyncedPendulumPhase.Value + PhaseOffset);
				CrumbHandleSuccess(Player);
				if (bIsCompletable && Data.CurrentSuccessCount == NrOfSuccessForComplete)
				{
					Data.PendulumPosition = Math::Sin((TWO_PI / Period) * Data.ActiveDuration + SyncedPendulumPhase.Value);
					Widget.CurrentPendulumAngle = -Data.PendulumPosition * MaxAngle;
					if (HasControl())
						CrumbHandleComplete(Player);
				}
			}
		}
		else
		{
			if (HasControl())
			{
				CrumbHandleFail(InteractingPlayer);
			}
		}

		Data.FailDirection = -Math::Sign(Data.PendulumPosition - Data.PrevPendulumPosition);
	}
}