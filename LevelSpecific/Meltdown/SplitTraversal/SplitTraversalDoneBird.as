class ASplitTraversalDoneBird : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USphereComponent FantasySphereComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent BirdRoot;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USphereComponent ScifiSphereComp;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent DroneRoot;

	UPROPERTY(DefaultComponent, Attach = DroneRoot)
	USceneComponent ScifiPropellerRoot;

	UPROPERTY(DefaultComponent, Attach = DroneRoot)
	USceneComponent ScifiPropellerRoot2;

	UPROPERTY(EditInstanceOnly)
	AActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	float TargetSpeed = 500.0;
	float Speed = 0.0;
	float SplineProgress = 0.0;
	float RotationAcceleration = 2.0;
	FHazeAcceleratedVector AcceleratedLocation;
	FHazeAcceleratedRotator AccRot;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike SpeedTimeLike;
	default SpeedTimeLike.UseSmoothCurveZeroToOne();
	default SpeedTimeLike.Duration = 2.0;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		SplineComp = UHazeSplineComponent::Get(SplineActor);

		SpeedTimeLike.BindUpdate(this, n"SpeedTimeLikeUpdate");

		FantasySphereComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap");
		ScifiSphereComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bActive)
			return;

		SplineProgress += Speed * DeltaSeconds;

		ScifiPropellerRoot.AddRelativeRotation(FRotator(0.0, 0.0, Speed));
		ScifiPropellerRoot2.AddRelativeRotation(FRotator(0.0, 0.0, Speed));

		if (SplineProgress >= SplineComp.SplineLength)
			AddActorDisable(this);

		FVector Location = SplineComp.GetWorldLocationAtSplineDistance(SplineProgress);
		AcceleratedLocation.AccelerateTo(Location, 2.0, DeltaSeconds);

		BirdRoot.SetWorldLocation(AcceleratedLocation.Value);
		DroneRoot.SetWorldLocation(AcceleratedLocation.Value + FVector::ForwardVector * 500000.0);

		FRotator Rotation = (Location - AcceleratedLocation.Value).Rotation();
		AccRot.AccelerateTo(Rotation, RotationAcceleration, DeltaSeconds);
		FantasyRoot.SetWorldRotation(AccRot.Value);
		ScifiRoot.SetWorldRotation(AccRot.Value);
	}

	UFUNCTION()
	private void HandleOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		FantasySphereComp.bGenerateOverlapEvents = false;
		ScifiSphereComp.bGenerateOverlapEvents = false;
		Activate();
	}

	private void Activate()
	{
		bActive = true;
		SpeedTimeLike.Play();
		AcceleratedLocation.SnapTo(SplineComp.GetWorldLocationAtSplineFraction(0.0));
		AccRot.SnapTo(ActorRotation);
		BP_Activate();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activate(){}

	UFUNCTION()
	private void SpeedTimeLikeUpdate(float CurrentValue)
	{
		Speed = Math::Lerp(0.0, TargetSpeed, CurrentValue);
		RotationAcceleration = Math::Lerp(2.0, 0.0, CurrentValue);
	}
};