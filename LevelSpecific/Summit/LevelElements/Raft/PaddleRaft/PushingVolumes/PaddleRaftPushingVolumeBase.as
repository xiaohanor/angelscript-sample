UCLASS(Abstract, NotPlaceable, HideCategories = "Physics Collision Tags Animation Actor Cooking Debug HLOD Navigation Rendering")
class APaddleRaftPushingVolumeBase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	float MaxForceSize = 500;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                        UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto PaddleRaft = Cast<APaddleRaft>(OtherActor);
		if (PaddleRaft == nullptr)
			return;

		if (PaddleRaft.OverlappedPushingVolumes.Contains(this))
			PaddleRaft.OverlappedPushingVolumes.Remove(this);
	}

	UFUNCTION()
	private void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		auto PaddleRaft = Cast<APaddleRaft>(OtherActor);
		if (PaddleRaft == nullptr)
			return;

		PaddleRaft.OverlappedPushingVolumes.AddUnique(this);
	}

	UFUNCTION()
	FVector GetForceAtPointInOverlap(FVector WorldLocation)
	{
		return FVector::ZeroVector;
	}
};