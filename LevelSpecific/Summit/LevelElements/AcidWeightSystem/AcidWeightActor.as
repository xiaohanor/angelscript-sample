class AAcidWeightActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent WeightEndLocation;
	default WeightEndLocation.SetWorldScale3D(FVector(5.0));

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent AcidPoolMesh;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	FVector StartLocation;
	FVector MoveDirection;
	FVector AcidPoolStartScale;

	float LastAcidHitDeactivateTime;
	float LastActidHitDeactivateDuration = 3.0;
	FHazeAcceleratedFloat AcidAlpha;
	float TargetAlpha;
	float AcidWeightIncreaseValue = 0.1;
	float MoveDistance;

	bool bTestActivate;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");

		StartLocation = MeshRoot.RelativeLocation;
		MoveDirection = (WeightEndLocation.RelativeLocation - StartLocation).GetSafeNormal();
		MoveDistance = (WeightEndLocation.RelativeLocation - StartLocation).Size();

		AcidPoolStartScale = AcidPoolMesh.GetRelativeScale3D();
		AcidPoolMesh.SetRelativeScale3D(FVector(AcidPoolStartScale.X, AcidPoolStartScale.Y, 0.1));
		AcidPoolMesh.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AcidAlpha.AccelerateTo(TargetAlpha, 1.5, DeltaTime);

		if (AcidAlpha.Value > 0.0 && AcidPoolMesh.GetbHiddenInGame())
			AcidPoolMesh.SetHiddenInGame(false);
		else if (AcidAlpha.Value == 0.0 && !AcidPoolMesh.GetbHiddenInGame())
			AcidPoolMesh.SetHiddenInGame(true);
		
		AcidPoolMesh.SetRelativeScale3D(FVector(AcidPoolStartScale.X, AcidPoolStartScale.Y, AcidPoolStartScale.Z * AcidAlpha.Value));
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		TargetAlpha += AcidWeightIncreaseValue;
		TargetAlpha = Math::Clamp(TargetAlpha, 0.0, 1.0);
		bTestActivate = true;
		LastAcidHitDeactivateTime = Time::GameTimeSeconds + LastActidHitDeactivateDuration;
	}

	FVector GetTargetLocation()
	{
		float MoveValue = MoveDistance * AcidAlpha.Value;
		FVector Target = StartLocation + MoveDirection * MoveValue;
		return Target;
	}
}