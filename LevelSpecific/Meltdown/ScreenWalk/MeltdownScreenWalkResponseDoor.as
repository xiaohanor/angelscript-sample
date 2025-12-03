class AMeltdownScreenWalkResponseDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Door;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent DoorTarget;
	default DoorTarget.bHiddenInGame = true;
	default DoorTarget.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(EditAnywhere)
	AMeltdownScreenWalkMioButtonActor Button;

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

		Button.PlayerWeightActive.AddUFunction(this, n"ActivateDoor");
		Button.PlayerWeightNotActive.AddUFunction(this, n"DeactivateDoor");
	}


	UFUNCTION()
	private void ActivateDoor()
	{
			MoveDoor.Play();
			MoveDoor.PlayRate = 1.0;
	}

	UFUNCTION()
	private void DeactivateDoor()
	{
			MoveDoor.Reverse();
			MoveDoor.PlayRate = 0.02;
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		Door.SetRelativeLocation(Math::Lerp(DoorStart,DoorEnd, CurrentValue));
	}

};