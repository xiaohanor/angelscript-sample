class ASummitPipeDoorLock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LockMesh;

	FHazeAcceleratedFloat AccelRightOffset;
	float RightOffset;
	float TargetRightOffset = 0.0;
	float MaxOffset = 300.0;

	UPROPERTY(EditInstanceOnly)
	ASummitPipeDoor Door;

	UPROPERTY(EditInstanceOnly)
	int Direction = 1;

	FVector RelativeStartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Direction > 0)
		{
			AttachToComponent(Door.RDoor, NAME_None, EAttachmentRule::KeepWorld);
		}
		else if (Direction < 0)
		{
			AttachToComponent(Door.LDoor, NAME_None, EAttachmentRule::KeepWorld);
		}

		RelativeStartLocation = ActorRelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RightOffset = Math::FInterpConstantTo(RightOffset, TargetRightOffset, DeltaSeconds, MaxOffset * 2.0);
		ActorRelativeLocation = RelativeStartLocation + FVector(0,RightOffset * Direction,0);
	}

	void Unlock()
	{
		TargetRightOffset = MaxOffset;
	}

	void Lock()
	{
		TargetRightOffset = 0.0;
	}
};