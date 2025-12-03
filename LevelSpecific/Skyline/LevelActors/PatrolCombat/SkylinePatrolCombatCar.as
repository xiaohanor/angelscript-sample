UCLASS(Abstract)
class USkylinePatrolCombatCarEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	ASkylinePatrolCombatCar Car = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Car = Cast<ASkylinePatrolCombatCar>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Idle() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FollowSpline() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Wait() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Trigger() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Disable() {}
}

struct FSkylinePatrolCombatCarSequence
{
	UPROPERTY(EditAnywhere)
	ESkylinePatrolCombatCarSequenceType Type = ESkylinePatrolCombatCarSequenceType::FollowSpline;

	UPROPERTY(EditAnywhere, Meta = (EditConditionHides, EditCondition = "Type == ESkylinePatrolCombatCarSequenceType::FollowSpline"))
	AActor ActorWithSpline;

	UPROPERTY(EditAnywhere, Meta = (EditConditionHides, EditCondition = "Type == ESkylinePatrolCombatCarSequenceType::FollowSpline"))
	float Speed = 2000.0;

	UPROPERTY(EditAnywhere, Meta = (EditConditionHides, EditCondition = "Type == ESkylinePatrolCombatCarSequenceType::Wait"))
	float WaitDuration = 0.0;

	UPROPERTY(EditAnywhere, Meta = (EditConditionHides, EditCondition = "Type == ESkylinePatrolCombatCarSequenceType::Trigger"))
	TArray<AHazeActorSpawnerBase> AcivateSpawners;

	UPROPERTY(EditAnywhere, Meta = (EditConditionHides, EditCondition = "Type == ESkylinePatrolCombatCarSequenceType::Trigger"))
	bool bTriggerInterface = false;
}

enum ESkylinePatrolCombatCarSequenceType
{
	Idle,
	FollowSpline,
	Wait,
	Trigger,
	Disable,
}

class ASkylinePatrolCombatCar : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USkylineHighwayFloatingComponent FloatingComp;

	UPROPERTY(DefaultComponent, Attach = FloatingComp)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditInstanceOnly)
	TArray<FSkylinePatrolCombatCarSequence> Sequence;
	int SequenceIndex = 0;

	ESkylinePatrolCombatCarSequenceType State;

	FSplinePosition SplinePosition;

	UPROPERTY(EditAnywhere)
	float Speed = 2000.0;

	UPROPERTY(EditAnywhere)
	float StopMargin = 1.0;

	UPROPERTY(EditAnywhere)
	float AccelerateToSpeed = 5.0;

	UPROPERTY(EditAnywhere)
	float AccelerateToDuration = 3.0;

	float WaitTime = 0.0;

	FHazeAcceleratedFloat AcceleratedFloat;

	FHazeAcceleratedTransform AcceleratedTransform;
	FTransform TargetTransform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetTransform = ActorTransform;

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");

		UpdtateState();

		if (State == ESkylinePatrolCombatCarSequenceType::FollowSpline)
			TargetTransform = SplinePosition.WorldTransformNoScale;

		AcceleratedTransform.SnapTo(TargetTransform);
	}
	
	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		if (State == ESkylinePatrolCombatCarSequenceType::Idle)
			UpdtateState();

		if (State == ESkylinePatrolCombatCarSequenceType::Disable)
		{
			if (IsActorDisabledBy(this))
				RemoveActorDisable(this);

			UpdtateState();
		}
	}

	private void ReachedEnd()
	{
		FloatingComp.FloatingData.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
//		PrintToScreen("PatrolCarState: " + State, 0.0, FLinearColor::Green);

		switch (State)
		{
			case ESkylinePatrolCombatCarSequenceType::Idle:
			{
				break;
			}

			case ESkylinePatrolCombatCarSequenceType::FollowSpline:
			{
				AcceleratedFloat.AccelerateTo(Speed, AccelerateToSpeed, DeltaSeconds);

				float SpeedScale = SplinePosition.RelativeScale3D.Z;

				SplinePosition.Move(AcceleratedFloat.Value * SpeedScale * DeltaSeconds);

				if (SplinePosition.IsAtEnd() && TargetTransform.EqualsNoScale(ActorTransform, StopMargin))
					UpdtateState();

				TargetTransform = SplinePosition.WorldTransformNoScale;

				break;
			}

			case ESkylinePatrolCombatCarSequenceType::Wait:
			{
				if (Time::GameTimeSeconds > WaitTime)
					UpdtateState();

				break;
			}

			default:
			{
				UpdtateState();
			}
		}

		AcceleratedTransform.AccelerateTo(TargetTransform, AccelerateToDuration, DeltaSeconds);
		ActorTransform = AcceleratedTransform.Value;
	}

	void UpdtateState()
	{
		if (Sequence.Num() == 0 || SequenceIndex == Sequence.Num())
			return;

		switch (Sequence[SequenceIndex].Type)
		{
			case ESkylinePatrolCombatCarSequenceType::Idle:
			{
				USkylinePatrolCombatCarEventHandler::Trigger_Idle(this);	

				break;
			}

			case ESkylinePatrolCombatCarSequenceType::FollowSpline:
			{
				auto Spline = UHazeSplineComponent::Get(Sequence[SequenceIndex].ActorWithSpline);

				if (Spline != nullptr)
					SplinePosition = Spline.GetSplinePositionAtSplineDistance(0.0);

				Speed = Sequence[SequenceIndex].Speed;

				if (State == ESkylinePatrolCombatCarSequenceType::Disable)
				{
					ActorTransform = SplinePosition.WorldTransformNoScale;
					AcceleratedTransform.SnapTo(ActorTransform);			
				}

				USkylinePatrolCombatCarEventHandler::Trigger_FollowSpline(this);

				break;
			}
			case ESkylinePatrolCombatCarSequenceType::Wait:
			{
				WaitTime = Time::GameTimeSeconds + Sequence[SequenceIndex].WaitDuration;

				USkylinePatrolCombatCarEventHandler::Trigger_Wait(this);

				break;
			}
		
			case ESkylinePatrolCombatCarSequenceType::Trigger:
			{
				for (auto Spawner : Sequence[SequenceIndex].AcivateSpawners)
					Spawner.ActivateSpawner();
				
				if (Sequence[SequenceIndex].bTriggerInterface)
					InterfaceComp.TriggerActivate();

				USkylinePatrolCombatCarEventHandler::Trigger_Trigger(this);

				break;
			}

			case ESkylinePatrolCombatCarSequenceType::Disable:
			{
				AddActorDisable(this);

				USkylinePatrolCombatCarEventHandler::Trigger_Disable(this);

				break;
			}
		
			default:
			{
				break;
			}
		}

		State = Sequence[SequenceIndex].Type;

		SequenceIndex++;
	}
};