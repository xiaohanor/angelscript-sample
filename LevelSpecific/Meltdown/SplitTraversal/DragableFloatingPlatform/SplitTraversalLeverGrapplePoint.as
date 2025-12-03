class ASplitTraversalLeverGrapplePoint : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UPerchPointComponent PerchComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		PerchComp.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"HandleGrappleFinished");
	}

	UFUNCTION()
	private void HandleGrappleFinished(AHazePlayerCharacter Player,
	                                   UGrapplePointBaseComponent GrapplePoint)
	{
		ForceComp.Force = FVector::UpVector * -1000.0;
	}
};