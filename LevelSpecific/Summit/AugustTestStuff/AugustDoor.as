event void FOnDoorOpened(float DoorSpeed, int DoorMoveDirection);

class AAugustDoor : AHazeActor
{
	FOnDoorOpened OnDoorOpened;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent DoorComp1;
	default DoorComp1.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default DoorComp1.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent DoorComp2;
	default DoorComp2.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default DoorComp2.bCanEverAffectNavigation = false;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DoorLocation1;
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DoorLocation2;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent HazeMoveComp;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DoorOpenSpeed;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int DoorDirection;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DoorMoveDistance = 500.0;

	UPROPERTY(EditAnywhere)
	FVector StartLocationDoor1;

	UPROPERTY(EditAnywhere)
	FVector StartLocationDoor2;

	UPROPERTY()
	float Test;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocationDoor1 = DoorComp1.RelativeLocation;
		StartLocationDoor2 = DoorComp2.RelativeLocation;
		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		DoorOpened();
	}

	UFUNCTION(BlueprintEvent)
	void DoorOpened()
	{

	}
}

