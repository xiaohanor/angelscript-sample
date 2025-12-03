class ASplitTraversalSwingRail : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsSplineFollowComponent SplineFollowComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;

	UPROPERTY(DefaultComponent, Attach = SplineFollowComp)
	USwingPointComponent SwingComp;

	FVector InitalLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitalLocation = SplineFollowComp.RelativeLocation;
		SwingComp.OnPlayerDetachedEvent.AddUFunction(this, n"HandleSwingDetached");
	}

	UFUNCTION()
	private void HandleSwingDetached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		Timer::SetTimer(this, n"DelayedTeleportSwing", 0.2);
	}

	UFUNCTION()
	void DelayedTeleportSwing()
	{
		SplineFollowComp.SetRelativeLocation(InitalLocation);
		SplineFollowComp.ResetInternalState();
	}
};