struct FSkylineCarChaseFollowerData
{
	UPROPERTY()
	FVector TargetLocation;

	UPROPERTY()
	float Duration = 3.0;

	UPROPERTY()
	bool bWaitForEvent;

	FInstigator Instigator;
}

class ASkylineCarChaseFollower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Billboard;

	ASkylineFlyingCar FlyingCar;

	UPROPERTY(EditAnywhere)
	ASkylineCarChaseTrigger Trigger;

	UPROPERTY(EditAnywhere)
	FVector StartLocation;

	UPROPERTY(EditAnywhere)
	TArray<FSkylineCarChaseFollowerData> Moves;

	TInstigated<FSkylineCarChaseFollowerData> InstigatedMove;

	int MoveIndex = -1;

	FHazeAcceleratedVector CurrentLocation;

	float TimeStamp = 0.0;

	UPROPERTY(EditAnywhere)
	FVector BobbingSpeed = FVector(1.0, 0.5, 2.0);

	UPROPERTY(EditAnywhere)
	FVector BobbingDistance = FVector(50.0, 50.0, 100.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentLocation.SnapTo(StartLocation);

		Disable();
	
		if (Trigger != nullptr)
			Trigger.OnFlyingCarEntered.AddUFunction(this, n"OnTrigger");
	}

	UFUNCTION()
	private void OnTrigger(ASkylineFlyingCar OverlappingFlyingCar)
	{
	//	PrintScaled("OnTrigger by: " + OverlappingFlyingCar, 3.0, FLinearColor::Green, 3.0);
		ApplyNextMove();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (FlyingCar == nullptr)
			return;

		if (!InstigatedMove.IsDefaultValue())
		{
		//	PrintScaled("InstigatedMove: " + InstigatedMove.Get().TargetLocation, 0.0, FLinearColor::Green, 3.0);

			CurrentLocation.AccelerateTo(InstigatedMove.Get().TargetLocation, InstigatedMove.Get().Duration, DeltaSeconds);

			if (!InstigatedMove.Get().bWaitForEvent && Time::GameTimeSeconds >= TimeStamp)
				ApplyNextMove();
		}

		UHazeSplineComponent Spline = FlyingCar.ActiveHighway.HighwaySpline;

		FSplinePosition FlyingCarSplinePosition = Spline.GetClosestSplinePositionToWorldLocation(FlyingCar.ActorLocation);
		FSplinePosition CurrentSplinePosition = Spline.GetSplinePositionAtSplineDistance(FlyingCarSplinePosition.CurrentSplineDistance + CurrentLocation.Value.X);

		FVector BobbingOffset;
		BobbingOffset.X = Math::Sin((Time::GameTimeSeconds + InstigatedMove.Get().TargetLocation.Size()) * BobbingSpeed.X) * BobbingDistance.X;
		BobbingOffset.Y = Math::Sin((Time::GameTimeSeconds + InstigatedMove.Get().TargetLocation.Size()) * BobbingSpeed.Y) * BobbingDistance.Y;
		BobbingOffset.Z = Math::Sin((Time::GameTimeSeconds + InstigatedMove.Get().TargetLocation.Size()) * BobbingSpeed.Z) * BobbingDistance.Z;

		FVector CurrentWorldLocation = CurrentSplinePosition.WorldTransformNoScale.TransformPositionNoScale(CurrentLocation.Value + BobbingOffset);
		FQuat CurrentRotation = CurrentSplinePosition.WorldRotation; // * FQuat::MakeFromXZ(CurrentSplinePosition.WorldTransformNoScale.TransformVectorNoScale(CurrentLocation.Velocity), CurrentSplinePosition.WorldForwardVector);

		SetActorLocationAndRotation(CurrentWorldLocation, CurrentRotation);
	}

	UFUNCTION()
	void FollowFlyingCar(ASkylineFlyingCar FlyingCarToFollow)
	{
		FlyingCar = FlyingCarToFollow;
	}

	UFUNCTION()
	void InsitgateMove(FSkylineCarChaseFollowerData InMove, FInstigator Instigator)
	{
		FSkylineCarChaseFollowerData Move = InMove;
		Move.Instigator = Instigator;
		InstigatedMove.Apply(Move, Instigator, EInstigatePriority::High);
		TimeStamp = Time::GameTimeSeconds + InstigatedMove.Get().Duration;

	//	PrintScaled("InstigatedMove" + InstigatedMove.Get().TargetLocation, 5.0, FLinearColor::Yellow, 3.0);

		Enable();
	}

	UFUNCTION()
	void ApplyNextMove()
	{
		InstigatedMove.Clear(InstigatedMove.Get().Instigator);

		if (MoveIndex < Moves.Num() - 1)
		{
		//	PrintScaled("New Move", 1.0, FLinearColor::Green, 5.0);
			Enable();

			MoveIndex++;
			InstigatedMove.Apply(Moves[MoveIndex], this);
			TimeStamp = Time::GameTimeSeconds + InstigatedMove.Get().Duration;
		}
		else
		{
		//	PrintScaled("Disable", 2.0, FLinearColor::Green, 5.0);
			Disable();
		}
	}

	UFUNCTION()
	void Enable()
	{
		if (FlyingCar == nullptr)
			for (auto Player : Game::Players)
			{
				auto PilotComponent = USkylineFlyingCarPilotComponent::Get(Player);
				if (PilotComponent != nullptr && PilotComponent.Car != nullptr)
				{
					FlyingCar = PilotComponent.Car;
					break;
				}
			}

	//	PrintScaled("FlyingCar: " + FlyingCar, 3.0, FLinearColor::Green, 5.0);

		RemoveActorDisable(this);
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (AActor Actor : AttachedActors)
			Actor.RemoveActorDisable(this);
	}

	UFUNCTION()
	void Disable()
	{
		AddActorDisable(this);
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (AActor Actor : AttachedActors)
			Actor.AddActorDisable(this);
	}
}