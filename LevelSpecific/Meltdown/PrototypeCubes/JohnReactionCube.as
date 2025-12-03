class AJohnReactionCube : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshCube;

	UPROPERTY(EditAnywhere)
	float MinDistance = 700.0;

	UPROPERTY(EditAnywhere)
	AActor TargetActor;

	UPROPERTY(EditAnywhere)
	FVector OffsetLocation = FVector(0.0, 0.0, 500.0);
	float MaxHeightOffset = 600.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshCube.RelativeLocation = OffsetLocation * GetPercent();
	}

	UFUNCTION()
	float GetPercent()
	{
		float CurrentDistance = GetDistanceTo(TargetActor);

		if (CurrentDistance <= MinDistance)
			return 1.0 - (CurrentDistance / MinDistance);
		else	
			return 0.0;
	}
}