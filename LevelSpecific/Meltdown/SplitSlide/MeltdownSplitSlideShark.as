class AMeltdownSplitSlideShark : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UHazeSplineComponent SplineComp;
	float SplineProgress;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent SharkRoot;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent SharkDeathTriggerRoot;

	FHazeAcceleratedTransform AcceleratedTransform;

	UPROPERTY()
	float Speed = 1500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		AddActorDisable(this);
	}

	UFUNCTION()
	void Activate()
	{
		RemoveActorDisable(this);
		
		FQuat Rotation = SplineComp.GetWorldRotationAtSplineDistance(SplineProgress);
		FVector Location = SplineComp.GetWorldLocationAtSplineDistance(SplineProgress);
		FTransform TargetTransform;

		TargetTransform.Rotation = Rotation;
		TargetTransform.Location = Location;

		AcceleratedTransform.SnapTo(TargetTransform);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SplineProgress += DeltaSeconds * Speed;
		
		FQuat Rotation = SplineComp.GetWorldRotationAtSplineDistance(SplineProgress);
		FVector Location = SplineComp.GetWorldLocationAtSplineDistance(SplineProgress);
		FTransform TargetTransform;

		TargetTransform.Rotation = Rotation;
		TargetTransform.Location = Location;

		AcceleratedTransform.AccelerateTo(TargetTransform, 2.0, DeltaSeconds);

		SharkRoot.SetWorldTransform(AcceleratedTransform.Value);
		SharkDeathTriggerRoot.SetRelativeLocationAndRotation(SharkRoot.RelativeLocation, SharkRoot.RelativeRotation);
	}
};