
/**
 * When the coast train enters the collision box, the specified spline is
 * made into a closed loop, removing the previous connections leading up to it.
 */
class ACoastTrainInfiniteLoop : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere, Category = "Infinite Loop")
	AHazeActor SplineActor;

	UPROPERTY(DefaultComponent)
	UBoxComponent CloseLoopCollision;
	default CloseLoopCollision.BoxExtent = FVector(40.0, 200.0, 200.0);

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CloseLoopCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnCloseLoopCollisionOverlap");
	}
	

	UFUNCTION()
	private void OnCloseLoopCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                         UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                         bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto TrainDriver = Cast<ACoastTrainDriver>(OtherActor);
		if (TrainDriver != nullptr)
		{
			if (SplineActor == nullptr)
				return;
			auto Spline = UHazeSplineComponent::Get(SplineActor);
			if (Spline == nullptr)
				return;

			// Remove previous connections leading into this loop
			Spline.RemoveAllSplineConnections();

			FSplineConnection EndOfSplineConnection;
            EndOfSplineConnection.ExitSpline = Spline;
            EndOfSplineConnection.DistanceOnEntrySpline = Spline.GetSplineLength();
            EndOfSplineConnection.DistanceOnExitSpline = 0.0;
            EndOfSplineConnection.bCanEnterGoingForward = true;
            EndOfSplineConnection.bCanEnterGoingBackward = false;
            EndOfSplineConnection.bExitForwardOnSpline = true;
			EndOfSplineConnection.Instigator = this;
            Spline.AddSplineConnection(EndOfSplineConnection);

            FSplineConnection StartOfSplineConnection;
            StartOfSplineConnection.ExitSpline = Spline;
            StartOfSplineConnection.DistanceOnEntrySpline = 0.0;
            StartOfSplineConnection.DistanceOnExitSpline = Spline.GetSplineLength();
            StartOfSplineConnection.bCanEnterGoingForward = false;
            StartOfSplineConnection.bCanEnterGoingBackward = true;
            StartOfSplineConnection.bExitForwardOnSpline = false;
            StartOfSplineConnection.Instigator = this;
            Spline.AddSplineConnection(StartOfSplineConnection);
		}
	}
}