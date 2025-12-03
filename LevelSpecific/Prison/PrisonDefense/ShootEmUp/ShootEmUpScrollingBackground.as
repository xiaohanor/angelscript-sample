class AShootEmUpScrollingBackground : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ScrollingRoot;

	UPROPERTY(DefaultComponent, Attach = ScrollingRoot)
	UStaticMeshComponent Mesh1;

	UPROPERTY(DefaultComponent, Attach = ScrollingRoot)
	UStaticMeshComponent Mesh2;

	UPROPERTY(DefaultComponent, Attach = ScrollingRoot)
	UStaticMeshComponent Mesh3;

	UPROPERTY(DefaultComponent, Attach = ScrollingRoot)
	UStaticMeshComponent Mesh4;

	UPROPERTY(DefaultComponent, Attach = ScrollingRoot)
	UStaticMeshComponent Mesh5;

	float MaxOffset = 240000.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Mesh1.SetRelativeLocation(FVector(Mesh1.RelativeLocation.X - 20000.0 * DeltaTime, 0.0, 0.0));
		if (Mesh1.RelativeLocation.X <= -60000.0)
			Mesh1.SetRelativeLocation(FVector(MaxOffset, 0.0, 0.0));

		Mesh2.SetRelativeLocation(FVector(Mesh2.RelativeLocation.X - 20000.0 * DeltaTime, 0.0, 0.0));
		if (Mesh2.RelativeLocation.X <= -60000.0)
			Mesh2.SetRelativeLocation(FVector(MaxOffset, 0.0, 0.0));

		Mesh3.SetRelativeLocation(FVector(Mesh3.RelativeLocation.X - 20000.0 * DeltaTime, 0.0, 0.0));
		if (Mesh3.RelativeLocation.X <= -60000.0)
			Mesh3.SetRelativeLocation(FVector(MaxOffset, 0.0, 0.0));

		Mesh4.SetRelativeLocation(FVector(Mesh4.RelativeLocation.X - 20000.0 * DeltaTime, 0.0, 0.0));
		if (Mesh4.RelativeLocation.X <= -60000.0)
			Mesh4.SetRelativeLocation(FVector(MaxOffset, 0.0, 0.0));

		Mesh5.SetRelativeLocation(FVector(Mesh5.RelativeLocation.X - 20000.0 * DeltaTime, 0.0, 0.0));
		if (Mesh5.RelativeLocation.X <= -60000.0)
			Mesh5.SetRelativeLocation(FVector(MaxOffset, 0.0, 0.0));
	}
}