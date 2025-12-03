class AGameShowArenaDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent DoorMesh01;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent DoorMesh02;

	UPROPERTY()
	FHazeTimeLike CloseDoorTimelike;
	default CloseDoorTimelike.Duration = 4;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CloseDoorTimelike.BindUpdate(this, n"CloseDoorTimelikeUpdate");
	}

	UFUNCTION()
	private void CloseDoorTimelikeUpdate(float CurrentValue)
	{
		DoorMesh01.SetRelativeLocation(Math::Lerp(FVector(0, 400, 0), FVector::ZeroVector, CurrentValue));
		DoorMesh02.SetRelativeLocation(Math::Lerp(FVector(0, -400, 0), FVector::ZeroVector, CurrentValue));
	}

	UFUNCTION()
	void SnapDoorOpen()
	{
		DoorMesh01.SetRelativeLocation(FVector(0, 400, 0));
		DoorMesh02.SetRelativeLocation(FVector(0, -400, 0));
	}

	UFUNCTION()
	void CloseDoor()
	{
		CloseDoorTimelike.PlayFromStart();
	}
}