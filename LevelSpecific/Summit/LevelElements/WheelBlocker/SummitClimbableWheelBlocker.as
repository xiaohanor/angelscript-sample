class ASummitClimbableWheelBlocker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PitchRotateRoot;

	UPROPERTY(DefaultComponent, Attach = PitchRotateRoot)
	UStaticMeshComponent WheelMesh;

	UPROPERTY(DefaultComponent, Attach = PitchRotateRoot)
	UStaticMeshComponent ClimbableRimMesh;
	UPROPERTY(DefaultComponent, Attach = PitchRotateRoot)
	UStaticMeshComponent ClimbableRimMesh2;

	UPROPERTY(DefaultComponent, Attach = ClimbableRimMesh)
	UTeenDragonTailClimbableComponent ClimbComp;
	default ClimbComp.bIsPrimitiveParentExclusive = true;
	
	UPROPERTY(DefaultComponent, Attach = ClimbableRimMesh2)
	UTeenDragonTailClimbableComponent ClimbComp2;
	default ClimbComp2.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitClimbableWheelBlockerCapability");

	UPROPERTY(DefaultComponent)
	USummitDarkCaveChainedBallResponseComponent ResponseComp;
	default ResponseComp.bImpactOnlyOnce = true;

	UPROPERTY(EditInstanceOnly)
	ASummitWheelRotatingPlatforms RotatingPlatform;

	float RotationAmountPerHit = -40.0;

	FQuat TargetQuat;
	FQuat StartQuat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnSummitDarkCaveBallImpact.AddUFunction(this, n"OnSummitDarkCaveBallImpact");
	}

	UFUNCTION()
	private void OnSummitDarkCaveBallImpact()
	{
		TargetQuat *= FRotator(RotationAmountPerHit, 0, 0).Quaternion();
		RotatingPlatform.ActivateRotatingPlatforms();
	}
};