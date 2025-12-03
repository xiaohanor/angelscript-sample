class ASplitTraversalRotatingCatStatue : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UFauxPhysicsAxisRotateComponent RotateCompFantasy;

	UPROPERTY(DefaultComponent, Attach = RotateCompFantasy)
	USceneComponent ForceRoot;

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalThrowableGoldenIdolGrenade GoldenIdol;

	FHazeAcceleratedQuat AcceleratedQuat;

	bool bIdolActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		GoldenIdol.OnThrowableCrossedSplitScreen.AddUFunction(this, n"HandleIdolCrossedSplitScreen");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIdolActive)
		{
			//FVector Force = (GoldenIdol.FantasyProp.WorldLocation - ForceRoot.WorldLocation).GetSafeNormal() * 100.0;
			//RotateCompFantasy.ApplyForce(ForceRoot.WorldLocation, Force);
			
			FQuat TargetQuat = (GoldenIdol.FantasyProp.WorldLocation - FantasyRoot.WorldLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal().Rotation().Quaternion();
		
			AcceleratedQuat.AccelerateTo(TargetQuat, 2.0, DeltaSeconds);

			FantasyRoot.SetWorldRotation(AcceleratedQuat.Value);
		}
	}

	UFUNCTION()
	private void HandleIdolCrossedSplitScreen(bool bScifi)
	{
		bIdolActive = !bScifi;
	}
};