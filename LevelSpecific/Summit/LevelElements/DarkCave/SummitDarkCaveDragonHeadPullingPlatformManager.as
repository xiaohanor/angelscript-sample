enum ESummitDarkCaveDragonHeadPullingPlatformManagerState
{
	Idle,
	Waiting,
	GoingForward,
	HoldBeforeGoingBack,
	GoingBack
}

class ASummitDarkCaveDragonHeadPullingPlatformManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USummitDarkCaveDragonHeadPullingPlatformManagerDummyComponent DummyComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10));
#endif

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitDarkCaveMetalStatue Statue;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AActor DragonToAttach;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	TArray<AActor> PlatformsToGrab;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MoveDelay = 3.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MoveDuration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float HoldBeforeGoingBackDuration = 2.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MoveBackDuration = 3.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FRuntimeFloatCurve MoveCurve;
	default MoveCurve.AddDefaultKey(0.0, 0.0);
	default MoveCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MoveTotal = 2000.0;

	ESummitDarkCaveDragonHeadPullingPlatformManagerState State = ESummitDarkCaveDragonHeadPullingPlatformManagerState::Idle;

	float TimeLastChangedState;

	FVector StartLocation;
	FVector DragonStartLocation;
	FVector TargetLocation;

	FVector LastLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Statue != nullptr)
			Statue.OnCompleted.AddUFunction(this, n"OnStatueCompleted");
		// DragonToAttach.AttachToActor(this, n"NAME_None", EAttachmentRule::KeepWorld);

		StartLocation = ActorLocation;
		TargetLocation = StartLocation + ActorForwardVector * MoveTotal;
		LastLocation = ActorLocation;

		DragonStartLocation = DragonToAttach.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(State == ESummitDarkCaveDragonHeadPullingPlatformManagerState::Idle)
			return;

		float TimeSinceLastChangedState = Time::GetGameTimeSince(TimeLastChangedState);
		if(State == ESummitDarkCaveDragonHeadPullingPlatformManagerState::Waiting)
		{
			if(TimeSinceLastChangedState >= MoveDelay)
			{
				SetNewState(ESummitDarkCaveDragonHeadPullingPlatformManagerState::GoingForward);
			}
		}
		else if (State == ESummitDarkCaveDragonHeadPullingPlatformManagerState::GoingForward)
		{
			float MoveTimeAlpha = TimeSinceLastChangedState / MoveDuration;
			float MoveAlpha = MoveCurve.GetFloatValue(MoveTimeAlpha); 

			ActorLocation = Math::Lerp(StartLocation, TargetLocation, MoveAlpha);

			if(TimeSinceLastChangedState >= MoveDuration)
			{
				for(auto Platform : PlatformsToGrab)
				{
					Platform.AttachToActor(this, n"NAME_None", EAttachmentRule::KeepWorld);
				}
				BP_ReachedTarget();
				SetNewState(ESummitDarkCaveDragonHeadPullingPlatformManagerState::HoldBeforeGoingBack);
			}
		}
		else if(State == ESummitDarkCaveDragonHeadPullingPlatformManagerState::HoldBeforeGoingBack)
		{
			if(TimeSinceLastChangedState >= HoldBeforeGoingBackDuration)
			{
				SetNewState(ESummitDarkCaveDragonHeadPullingPlatformManagerState::GoingBack);
			}
		}
		else if(State == ESummitDarkCaveDragonHeadPullingPlatformManagerState::GoingBack)
		{
			float MoveTimeAlpha = TimeSinceLastChangedState / MoveBackDuration;
			float MoveAlpha = MoveCurve.GetFloatValue(MoveTimeAlpha); 

			ActorLocation = Math::Lerp(TargetLocation, StartLocation, MoveAlpha);

			if(TimeSinceLastChangedState >= MoveBackDuration)
			{
				SetNewState(ESummitDarkCaveDragonHeadPullingPlatformManagerState::Idle);
				BP_ReachedEnd();
			}
		}

		if(State == ESummitDarkCaveDragonHeadPullingPlatformManagerState::GoingBack)
		{
			DragonToAttach.ActorLocation = DragonStartLocation;
		}
		else
		{
			FVector DeltaLocation = ActorLocation - LastLocation;
			DragonToAttach.AddActorWorldOffset(DeltaLocation * 0.7);
		}

		LastLocation = ActorLocation; 
	}

	private void SetNewState(ESummitDarkCaveDragonHeadPullingPlatformManagerState NewState)
	{
		State = NewState;
		TimeLastChangedState = Time::GameTimeSeconds;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnStatueCompleted()
	{
		SetNewState(ESummitDarkCaveDragonHeadPullingPlatformManagerState::Waiting);
		BP_ManagerActivated();
	}

	UFUNCTION(BlueprintPure)
	ESummitDarkCaveDragonHeadPullingPlatformManagerState GetManagerState()
	{
		return State;
	}

	UFUNCTION(BlueprintEvent)
	void BP_ManagerActivated()
	{

	} 

	UFUNCTION(BlueprintEvent)
	void BP_ReachedTarget()
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_ReachedEnd()
	{

	}
};

#if EDITOR
class USummitDarkCaveDragonHeadPullingPlatformManagerDummyComponent : UActorComponent {};
class USummitDarkCaveDragonHeadPullingPlatformManagerComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitDarkCaveDragonHeadPullingPlatformManagerDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitDarkCaveDragonHeadPullingPlatformManagerDummyComponent>(Component);
		if(Comp == nullptr)
			return;
		auto Manager = Cast<ASummitDarkCaveDragonHeadPullingPlatformManager>(Comp.Owner);
		if(Manager == nullptr)
			return;

		DrawArrow(Manager.ActorLocation, Manager.ActorLocation + Manager.ActorForwardVector * Manager.MoveTotal, FLinearColor::Red, 200, 50, false);
	}
}
#endif