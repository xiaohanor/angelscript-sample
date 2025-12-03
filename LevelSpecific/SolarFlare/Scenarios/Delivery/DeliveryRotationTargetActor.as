class ADeliveryRotationTargetActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent OverlapComp;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UGizmoArrowComponent GizmoCompForward;
	default GizmoCompForward.Direction = FVector(1.0, 0.0, 0.0);
	UPROPERTY(DefaultComponent, Attach = Root)
	UGizmoArrowComponent GizmoCompUp;
	default GizmoCompUp.Direction = FVector(0.0, 0.0, 1.0);
	UPROPERTY(DefaultComponent, Attach = Root)
	UGizmoArrowComponent GizmoCompRight;
	default GizmoCompRight.Direction = FVector(0.0, 1.0, 0.0);
	
	default GizmoCompForward.Length = 1700.0; 
	default GizmoCompUp.Length = 1700.0; 
	default GizmoCompRight.Length = 1700.0; 
	default GizmoCompForward.Thickness = 20.0; 
	default GizmoCompUp.Thickness = 20.0; 
	default GizmoCompRight.Thickness = 20.0;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OverlapComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap"); 
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
	}
}