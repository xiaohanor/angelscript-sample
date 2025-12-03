class AMeltdownWorldSpinFallingObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Meshroot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshrootTarget;

	UPROPERTY(DefaultComponent, Attach = Meshroot)
	UStaticMeshComponent FallingObject;

	UPROPERTY(DefaultComponent, Attach = MeshrootTarget)
	UStaticMeshComponent FallingObjectTarget; 

	UPROPERTY(EditAnywhere)
	AMeltdownWorldSpinTreeTrunk Trunk;

	FRotator StartRot;
	FRotator TargetRot;

	UPROPERTY()
	FHazeTimeLike FallingTimelike;
	default FallingTimelike.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRot = Meshroot.RelativeRotation;
		TargetRot = MeshrootTarget.RelativeRotation;

		FallingTimelike.BindUpdate(this, n"OnUpdate");
	}

	UFUNCTION()
	void StartFalling()
	{
		FallingTimelike.PlayFromStart();
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		SetActorRelativeRotation(Math::LerpShortestPath(StartRot,TargetRot, CurrentValue));
	}
};