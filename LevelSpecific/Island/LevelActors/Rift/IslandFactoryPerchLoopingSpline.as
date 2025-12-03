event void FIslandFactoryPerchLoopingSplineEvent();

enum EIslandFactoryPerchLoopingSplineState
{
	InitialStopped,
	Moving,
	Stopped
}

UCLASS(Abstract)
class AIslandFactoryPerchLoopingSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AIslandFactorySplinePerch> PerchActorClass;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve MoveCurve;
	default MoveCurve.AddDefaultKey(0.0, 0.0);
	default MoveCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FRotator ObjectRelativeRotation = FRotator(0.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere)
	FVector RelativeLocation = FVector(0.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere)
	float InitialTimeOffset = 0.0;

	UPROPERTY(EditAnywhere)
	float MoveLengthPerStep = 1000.0;

	UPROPERTY(EditAnywhere)
	float StepDuration = 1.0;

	UPROPERTY(EditAnywhere)
	float StopDuration = 4.0;

	UPROPERTY(EditAnywhere)
	bool bReverse = false;

	TArray<FIslandLoopingObjectData> LoopingObjects;
	float CurrentCurveAlpha = 0.0;
	EIslandFactoryPerchLoopingSplineState State = EIslandFactoryPerchLoopingSplineState::InitialStopped;
	float TimeOfStopped = -100.0;
	float TimeOfStart = -100.0;
	float TimeOfStartMoving = -100.0;
	bool bSentToRemoteToMove = false;

	FIslandFactoryPerchLoopingSplineEvent OnStartMoving;
	FIslandFactoryPerchLoopingSplineEvent OnStopMoving;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeOfStart = Time::GetGameTimeSeconds();
		float AmountOfSteps = Spline.SplineLength / MoveLengthPerStep;
		int RoundedAmount = Math::RoundToInt(AmountOfSteps);

		float Distance = bReverse ? 0.0 : Spline.SplineLength;
		FSplinePosition SplinePos = FSplinePosition(Spline, Distance, !bReverse);

		float RemainingDistance = 0.0;
		for(int i = 0; i < RoundedAmount; i++)
		{
			FIslandLoopingObjectData Data;
			FTransform Transform = GetObjectTransformFromSplinePosition(SplinePos);
			Data.Actor = Cast<AHazeActor>(SpawnActor(PerchActorClass, Transform.Location, Transform.Rotator(), bDeferredSpawn = true));
			Data.Actor.MakeNetworked(this, i);
			FinishSpawningActor(Data.Actor);
			auto Perch = Cast<AIslandFactorySplinePerch>(Data.Actor);
			Perch.LoopingSpline = this;
			Perch.Initialize();
			Data.SplinePosition = SplinePos;
			SplinePos.Move(-MoveLengthPerStep, RemainingDistance);
			LoopingObjects.Add(Data);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Network::IsGameNetworked() && HasControl() && !bSentToRemoteToMove)
		{
			float TimeTo = GetDurationToNextMove();
			float CrumbSendTime = Time::EstimatedCrumbReachedDelay;
			if(TimeTo < CrumbSendTime)
				NetRemoteStartMoving();
		}

		switch(State)
		{
			case EIslandFactoryPerchLoopingSplineState::InitialStopped:
			{
				if(!HasControl())
					return;

				if(Time::GetGameTimeSince(TimeOfStart) > InitialTimeOffset)
				{
					LocalStartMoving();
				}

				break;
			}
			case EIslandFactoryPerchLoopingSplineState::Moving:
			{
				float PreviousCurveAlpha = CurrentCurveAlpha;
				CurrentCurveAlpha += DeltaTime / StepDuration;
				CurrentCurveAlpha = Math::Saturate(CurrentCurveAlpha);
				if(CurrentCurveAlpha == 1.0)
				{
					// Stop moving
					State = EIslandFactoryPerchLoopingSplineState::Stopped;
					TimeOfStopped = Time::GetGameTimeSeconds();
					OnStopMoving.Broadcast();
				}
				MoveByAlpha(PreviousCurveAlpha, CurrentCurveAlpha);
				
				break;
			}
			case EIslandFactoryPerchLoopingSplineState::Stopped:
			{
				if(!HasControl())
					return;

				if(Time::GetGameTimeSince(TimeOfStopped) > StopDuration)
				{
					LocalStartMoving();
				}

				break;
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetRemoteStartMoving()
	{
		bSentToRemoteToMove = true;
		if(HasControl())
			return;

		LocalStartMoving();
	}

	private void LocalStartMoving()
	{
		if(HasControl() && !bSentToRemoteToMove)
			NetRemoteStartMoving();

		if(State == EIslandFactoryPerchLoopingSplineState::Moving)
		{
			MoveByAlpha(CurrentCurveAlpha, 1.0);
		}

		CurrentCurveAlpha = 0.0;
		State = EIslandFactoryPerchLoopingSplineState::Moving;
		TimeOfStartMoving = Time::GetGameTimeSeconds();
		OnStartMoving.Broadcast();
		UIslandFactoryPerchLoopingSplineEventHandler::Trigger_OnStartMoving(this);
		bSentToRemoteToMove = false;
	}

	float GetDurationToNextMove() const
	{
		float Value = 0.0;
		switch(State)
		{
			case EIslandFactoryPerchLoopingSplineState::InitialStopped:
				Value = InitialTimeOffset - Time::GetGameTimeSince(TimeOfStart);
			break;
			case EIslandFactoryPerchLoopingSplineState::Moving:
				Value = StepDuration - Time::GetGameTimeSince(TimeOfStartMoving) + StopDuration;
			break;
			case EIslandFactoryPerchLoopingSplineState::Stopped:
				Value = StopDuration - Time::GetGameTimeSince(TimeOfStopped);
			break;
		}

		Value = Math::Max(0.0, Value);
		return Value;
	}

	void MoveByAlpha(float PreviousAlpha, float Alpha)
	{
		float PreviousValue = MoveCurve.GetFloatValue(PreviousAlpha);
		float CurrentValue = MoveCurve.GetFloatValue(Alpha);
		float Delta = CurrentValue - PreviousValue;

		for(int i = 0; i < LoopingObjects.Num(); i++)
		{
			FIslandLoopingObjectData& Current = LoopingObjects[i];
			float RemainingDistance = 0.0;
			Current.SplinePosition.Move(Delta * MoveLengthPerStep, RemainingDistance);
			if(RemainingDistance > 0.0)
			{
				Current.SplinePosition.Move(-Spline.SplineLength + RemainingDistance);
			}

			FTransform Transform = GetObjectTransformFromSplinePosition(Current.SplinePosition);
			Current.Actor.ActorLocation = Transform.Location;
			Current.Actor.ActorRotation = Transform.Rotator();

			if(RemainingDistance > 0.0)
			{
				Current.Actor.AddActorDisable(this);
				Current.Actor.RemoveActorDisable(this);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		for(FIslandLoopingObjectData Object : LoopingObjects)
		{
			Object.Actor.RemoveActorDisable(n"DisableComponentFromObjectSpline");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		for(FIslandLoopingObjectData Object : LoopingObjects)
		{
			Object.Actor.AddActorDisable(n"DisableComponentFromObjectSpline");
		}
	}

	FTransform GetObjectTransformFromSplinePosition(FSplinePosition SplinePos) const
	{
		FVector FinalLocation = SplinePos.WorldLocation + SplinePos.WorldTransform.TransformVectorNoScale(RelativeLocation);
		FRotator Rotation = (SplinePos.WorldRotation * ObjectRelativeRotation.Quaternion()).Rotator();
		return FTransform(Rotation, FinalLocation);
	}
}