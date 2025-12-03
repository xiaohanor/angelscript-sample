class AAIExposureManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Overlap);

	UPROPERTY(EditAnywhere)
	TArray<AAIExposureScenepointActor> ExposureCompArray;

	UPROPERTY(EditAnywhere)
	float TracesPerSecond = ExposureSettings::TracesRanPerSecond;

	float TraceTime;
	float TraceIntervals;
	int Index = 0;

	TArray<UAIExposureReceiverComponent> ExposureRecieverArray;

	UFUNCTION(CallInEditor)
	void SetExposurePointsWithinRange()
	{
	#if EDITOR
		ExposureCompArray.Empty();

		TArray<AAIExposureScenepointActor> ExposureArray = Editor::GetAllEditorWorldActorsOfClass(AAIExposureScenepointActor);

		for (auto It : ExposureArray)
		{
			auto Point = Cast<AAIExposureScenepointActor>(It);
			bool bWithinX = Point.ActorLocation.X < ActorLocation.X + (BoxComp.BoundsExtent.X) && Point.ActorLocation.X > ActorLocation.X - (BoxComp.BoundsExtent.X);
			bool bWithinY = Point.ActorLocation.Y < ActorLocation.Y + (BoxComp.BoundsExtent.Y) && Point.ActorLocation.Y > ActorLocation.Y - (BoxComp.BoundsExtent.Y);
			bool bWithinZ = Point.ActorLocation.Z < ActorLocation.Z + (BoxComp.BoundsExtent.Z) && Point.ActorLocation.Z > ActorLocation.Z - (BoxComp.BoundsExtent.Z);

			if (bWithinX && bWithinY && bWithinZ)
			{
				ExposureCompArray.Add(Point);
			}
		}
	#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TraceIntervals = 1.0 / TracesPerSecond;

		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		BoxComp.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");

		TArray<AActor> OverlappingActors;
		BoxComp.GetOverlappingActors(OverlappingActors);

		for (AActor OtherActor : OverlappingActors)
		{
			UAIExposureReceiverComponent ReceiveComp = UAIExposureReceiverComponent::Get(OtherActor);

			if (ReceiveComp != nullptr)
			{
				ExposureRecieverArray.Add(ReceiveComp);
			}			
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RunAllTraceScores();
	}

	void RunAllTraceScores()
	{
		if (Time::GameTimeSeconds > TraceTime)
		{
			TraceTime = Time::GameTimeSeconds + TraceIntervals;

			if (ExposureRecieverArray.Num() == 0)
				return;

			ExposureCompArray[Index].RunTraceScore(Game::Mio, TraceIntervals);
			ExposureCompArray[Index].RunTraceScore(Game::Zoe, TraceIntervals);

			for (UAIExposureReceiverComponent ReceiveComp : ExposureRecieverArray)
			{
				if (!ReceiveComp.ExposurePoints.Contains(ExposureCompArray[Index]))
				{
					ReceiveComp.ExposurePoints.Add(ExposureCompArray[Index]);
				}
			}

			if (Index >= ExposureCompArray.Num() - 1)
				Index = 0;
			else
				Index++;
		}
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		UAIExposureReceiverComponent ReceiveComp = UAIExposureReceiverComponent::Get(OtherActor);

		if (ReceiveComp != nullptr)
		{
			ExposureRecieverArray.Add(ReceiveComp);
		}
    }

    UFUNCTION()
    void TriggeredOnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		UAIExposureReceiverComponent ReceiveComp = UAIExposureReceiverComponent::Get(OtherActor);

		if (ReceiveComp != nullptr)
		{
			ExposureRecieverArray.Remove(ReceiveComp);
		}
    }
}