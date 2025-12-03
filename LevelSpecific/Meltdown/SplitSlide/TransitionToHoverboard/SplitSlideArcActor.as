class ASplitSlideArcActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	USceneComponent LandingLocationComp;

	UPROPERTY(EditInstanceOnly)
	float Gravity = 1000.0;

	UPROPERTY(EditInstanceOnly)
	float HorizontalSpeed = 500;

	TPerPlayer<bool> bPlayerLaunched;

	UPROPERTY(EditInstanceOnly)
	APerchPointActor MioGrapplePoint;

	UPROPERTY(EditInstanceOnly)
	APerchPointActor ZoeGrapplePoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MioGrapplePoint.PerchPointComp.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"HandleInitiatedGrapple");
		ZoeGrapplePoint.PerchPointComp.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"HandleInitiatedGrapple");
	}

	UFUNCTION()
	private void HandleInitiatedGrapple(AHazePlayerCharacter Player,
	                                    UGrapplePointBaseComponent TargetedGrapplePoint)
	{
		bPlayerLaunched[Player] = false;
	}

	UFUNCTION()
	void ActivateTransitionToHoverboard()
	{
		for (auto Player : Game::Players)
			bPlayerLaunched[Player] = true;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		FTraversalTrajectory Trajectory;
		Trajectory.LaunchLocation = ActorLocation;
		Trajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(
			ActorLocation,
			LandingLocationComp.WorldLocation,
			Gravity,
			HorizontalSpeed
		);

		Trajectory.Gravity = FVector::UpVector * Gravity;
		Trajectory.LandLocation = LandingLocationComp.WorldLocation;
		Trajectory.DrawDebug(FLinearColor::White, 0, 5, 100);
	}
#endif
};