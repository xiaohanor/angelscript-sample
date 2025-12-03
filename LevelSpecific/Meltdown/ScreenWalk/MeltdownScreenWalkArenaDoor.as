class AMeltdownScreenWalkArenaDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Door;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent DoorTarget;

	FVector DoorStart;
	FVector DoorEnd;

	FHazeTimeLike MoveDoor;
	default MoveDoor.Duration = 1.0;
	default MoveDoor.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		DoorStart = Door.RelativeLocation;
		DoorEnd = DoorTarget.RelativeLocation;

		MoveDoor.BindUpdate(this, n"OnUpdate");
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		Door.SetRelativeLocation(Math::Lerp(DoorStart,DoorEnd, CurrentValue));
	}

	UFUNCTION(BlueprintCallable)
	void OpenDoor()
	{
		MoveDoor.ReverseFromEnd();
	}

	UFUNCTION(BlueprintCallable)
	void CloseDoor()
	{
		MoveDoor.PlayFromStart();
	}
};