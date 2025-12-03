event void FonDoorOpen();

class ASpaceWalkDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Door;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent DoorEnd;

	UPROPERTY(DefaultComponent)
	UDisableComponent Disable;

	UPROPERTY()
	FonDoorOpen DoorOpen;

	UPROPERTY()
	FVector DoorStart;

	UPROPERTY()
	FVector DoorTarget;

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike  OpenDoor;
	default OpenDoor.Duration = 1.0;
	default OpenDoor.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoorStart = Door.RelativeLocation;

		DoorTarget = DoorEnd.RelativeLocation;
	}

	UFUNCTION(BlueprintCallable)
	void BP_CallDoorOpen()
	{
		DoorOpen.Broadcast();
		USpaceWalkDoorEventHandler::Trigger_OpenDoor(this);	
	}

	UFUNCTION(BlueprintCallable)
	void BP_DoorClosed()
	{
		USpaceWalkDoorEventHandler::Trigger_DoorOpened(this);	
	}
};