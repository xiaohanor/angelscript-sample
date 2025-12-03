class USkylineRailingSlideComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineRailingSlideComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto RailingSlideComp = Cast<USkylineRailingSlideComponent>(InComponent);

		float SegmentLenght = 50.0;

		int Segments = Math::FloorToInt(RailingSlideComp.Spline.SplineLength / SegmentLenght);

		SegmentLenght = RailingSlideComp.Spline.SplineLength / Segments;

		for (int i = 0; i <= Segments; i++)
		{
			FVector LineStart;
			FVector LineEnd;

			LineStart = RailingSlideComp.Spline.GetWorldTransformAtSplineDistance(i * SegmentLenght).TransformPositionNoScale(RailingSlideComp.RailingOffset);
			LineEnd = RailingSlideComp.Spline.GetWorldTransformAtSplineDistance((i + 1) * SegmentLenght).TransformPositionNoScale(RailingSlideComp.RailingOffset);

			DrawLine(LineStart, LineEnd, FLinearColor::Yellow, 5.0);
		}
	}
}

class USkylineRailingSlideComponent : UActorComponent
{
	UHazeSplineComponent Spline;

	UPROPERTY(EditAnywhere)
	FVector RailingOffset = FVector::ZeroVector;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent OnRailSlideStartEvent;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent OnRailSlideStopEvent;

	private UHazeAudioEmitter SlideAudioEmitter;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Trigger = UBoxComponent::Create(Owner);
		Trigger.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
		Trigger.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

		Spline = UHazeSplineComponent::Get(Owner);
		Spline.PositionBoxComponentToContainEntireSpline(Trigger, 500.0);
	
		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		Trigger.OnComponentEndOverlap.AddUFunction(this, n"HandleEndOverlap");
	
		auto PropLine = Cast<APropLine>(Owner);
		if (PropLine != nullptr)
		{
			if (!PropLine.bGameplaySpline)
				Print("WARNING! PropLine: " + Owner.ActorNameOrLabel + " has no gameplay spline and will break in cooked!", 5.0, FLinearColor::Red);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
//		DrawDebug();
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto UserComp = USkylineRailingSlideUserComponent::Get(OtherActor);
		if (UserComp != nullptr)
			UserComp.RailingSlides.Add(this);
	}

	UFUNCTION()
	private void HandleEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto UserComp = USkylineRailingSlideUserComponent::Get(OtherActor);
		if (UserComp != nullptr)
			UserComp.RailingSlides.Remove(this);
	}

	void DrawDebug()
	{
		float SegmentLenght = 50.0;

		int Segments = Math::FloorToInt(Spline.SplineLength / SegmentLenght);

		SegmentLenght = Spline.SplineLength / Segments;

		for (int i = 0; i <= Segments; i++)
		{
			FVector LineStart;
			FVector LineEnd;

			LineStart = Spline.GetWorldTransformAtSplineDistance(i * SegmentLenght).TransformPositionNoScale(RailingOffset);
			LineEnd = Spline.GetWorldTransformAtSplineDistance((i + 1) * SegmentLenght).TransformPositionNoScale(RailingOffset);
			Debug::DrawDebugLine(LineStart, LineEnd, FLinearColor::Yellow, 5.0, 0.0);
		}
	}

	void StartRailSlideAudio(AHazePlayerCharacter Player)
	{
		if(OnRailSlideStartEvent == nullptr)
			return;

		auto Emitter = Player.PlayerAudioComponent.GetAnyEmitter();
		Emitter.PostEvent(OnRailSlideStartEvent);
	}

	void StopRailSlideAudio(AHazePlayerCharacter Player)
	{
		if(OnRailSlideStopEvent == nullptr)
			return;

		auto Emitter = Player.PlayerAudioComponent.GetAnyEmitter();
		Emitter.PostEvent(OnRailSlideStopEvent);
	}
};