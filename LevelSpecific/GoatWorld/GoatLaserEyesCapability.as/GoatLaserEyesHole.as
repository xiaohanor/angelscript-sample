class AGoatLaserEyesHole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HoleRoot;

	UPROPERTY(DefaultComponent, Attach = HoleRoot)
	UStaticMeshComponent HoleMesh;

	UPROPERTY(DefaultComponent, Attach = HoleRoot)
	USceneComponent TopRoot;

	UPROPERTY(DefaultComponent, Attach = TopRoot)
	UStaticMeshComponent TopMesh;

	UPROPERTY(DefaultComponent, Attach = HoleRoot)
	USceneComponent LeftRoot;

	UPROPERTY(DefaultComponent, Attach = LeftRoot)
	UStaticMeshComponent LeftMesh;

	UPROPERTY(DefaultComponent, Attach = HoleRoot)
	USceneComponent RightRoot;

	UPROPERTY(DefaultComponent, Attach = RightRoot)
	UStaticMeshComponent RightMesh;

	UPROPERTY(DefaultComponent, Attach = HoleRoot)
	UBoxComponent LaserCollider;

	UPROPERTY(DefaultComponent, Attach = HoleRoot)
	UGoatLaserEyesAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent)
	UGoatLaserEyesResponseComponent LaserEyesResponseComp;

	float CurrentSize = 0.1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaserEyesResponseComp.OnLaserEyesStart.AddUFunction(this, n"LaserEyesStart");
		LaserEyesResponseComp.OnLaserEyesStop.AddUFunction(this, n"LaserEyesStop");
	}

	UFUNCTION()
	private void LaserEyesStart()
	{

	}

	UFUNCTION()
	private void LaserEyesStop()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float TargetSize = LaserEyesResponseComp.bLasered ? 0.9 : 0.1;
		float Speed = LaserEyesResponseComp.bLasered ? 1.5 : 0.25;
		CurrentSize = Math::FInterpTo(CurrentSize, TargetSize, DeltaTime, Speed);
		HoleMesh.SetRelativeScale3D(FVector(1.0, CurrentSize, CurrentSize));

		float Alpha = Math::GetMappedRangeValueClamped(FVector2D(0.1, 1.0), FVector2D(0.0, 1.0), CurrentSize);

		float TopOffset = Math::Lerp(60.0, 600.0, Alpha);
		TopRoot.SetRelativeLocation(FVector(0.0, 0.0, TopOffset));

		float TopScale = Math::Lerp(0.6, 6.0, Alpha);
		TopMesh.SetRelativeScale3D(FVector(1.0, TopScale, 5.4));

		float RightOffset = Math::Lerp(-30.0, -300.0, Alpha);
		RightRoot.SetRelativeLocation(FVector(0.0, RightOffset, 300.0));

		float LeftOffset = Math::Lerp(30.0, 300.0, Alpha);
		LeftRoot.SetRelativeLocation(FVector(0.0, LeftOffset, 300.0));
	}
}