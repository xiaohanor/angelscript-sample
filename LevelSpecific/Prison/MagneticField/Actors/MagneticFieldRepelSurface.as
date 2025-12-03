UCLASS(Abstract)
class AMagneticFieldRepelSurface : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SurfaceRoot;

	UPROPERTY(DefaultComponent, Attach = SurfaceRoot)
	UStaticMeshComponent SurfaceMesh;

	UPROPERTY(DefaultComponent, Attach = SurfaceRoot, ShowOnActor)
	UMagneticFieldRepelComponent RepelComponent;
	default RepelComponent.RelativeLocation = FVector(0.0, 0.0, 35.0);

	UPROPERTY(EditAnywhere, Category = "Magnetic Field Repel")
	bool bWalkable = true;

	UPROPERTY(BlueprintReadOnly)
	FMagneticFieldRepelOnPlayerLaunched OnPlayerLaunchedEvent;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bWalkable)
			SurfaceMesh.AddTag(ComponentTags::Walkable);
		else
			SurfaceMesh.RemoveTag(ComponentTags::Walkable);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RepelComponent.OnPlayerLaunchedEvent.AddUFunction(this, n"OnPlayerLaunched");
	}

	UFUNCTION()
	private void OnPlayerLaunched(AHazePlayerCharacter Player)
	{
		OnPlayerLaunchedEvent.Broadcast(Player);
	}
}