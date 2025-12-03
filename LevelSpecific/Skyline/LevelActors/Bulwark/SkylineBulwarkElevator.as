UCLASS(Abstract)
class USkylineBulwarkElevatorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnElevatorStart()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnElevatorArrive()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorClose()
	{
	}
};	

class ASkylineBulwarkElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USceneComponent ElevatorRoot;
	
	UPROPERTY(EditAnywhere)
	FHazeTimeLike ElevatorUpTimeLike;
	UPROPERTY()
	FHazeTimeLike FrontDoorTimeLike;
	UPROPERTY()
	FHazeTimeLike BackDoorTimeLike;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	USceneComponent FrontDoor;
	UPROPERTY(DefaultComponent, Attach = FrontDoor)
	USceneComponent FrontLeftDoorPivot;
	UPROPERTY(DefaultComponent, Attach = FrontDoor)
	USceneComponent FrontRightDoorPivot;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	USceneComponent BackDoor;
	UPROPERTY(DefaultComponent, Attach = BackDoor)
	USceneComponent BackLeftDoorPivot;
	UPROPERTY(DefaultComponent, Attach = BackDoor)
	USceneComponent BackRightDoorPivot;

	UPROPERTY(DefaultComponent)
	UBoxComponent FrontDoorTrigger;
	default FrontDoorTrigger.BoxExtent = FVector::OneVector * 100.0;
	default FrontDoorTrigger.bGenerateOverlapEvents = true;
	default FrontDoorTrigger.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default FrontDoorTrigger.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent)
	UBoxComponent BackDoorTrigger;
	default BackDoorTrigger.BoxExtent = FVector::OneVector * 100.0;
	default BackDoorTrigger.bGenerateOverlapEvents = true;
	default BackDoorTrigger.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BackDoorTrigger.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	

	TPerPlayer<bool> IsInside;
	bool bHasGoneUp = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FrontDoorTrigger.OnComponentBeginOverlap.AddUFunction(this, n"FrontDoorHandleBeginOverlap");
		FrontDoorTrigger.OnComponentEndOverlap.AddUFunction(this, n"FrantDoorHandleEndOverlap");

		BackDoorTrigger.OnComponentBeginOverlap.AddUFunction(this, n"BackDoorHandleBeginOverlap");
		BackDoorTrigger.OnComponentEndOverlap.AddUFunction(this, n"BackHandleEndOverlap");
		
		ElevatorUpTimeLike.BindUpdate(this, n"AnimUpdate");
		ElevatorUpTimeLike.BindFinished(this, n"HandleAnimFinished");

		FrontDoorTimeLike.BindUpdate(this, n"FrontDoorTimeLikeAnimUpdate");
		FrontDoorTimeLike.BindFinished(this, n"FrontDoorTimeLikeFinished");

		BackDoorTimeLike.BindUpdate(this, n"BackDoorTimeLikeAnimUpdate");
		
	}


	UFUNCTION()
	private void BackHandleEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                  UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		IsInside[Player] = false;

		CloseBackDoors();	
	}

	void CloseBackDoors()
	{
		BackDoorTimeLike.Reverse();
	}

	UFUNCTION()
	private void BackDoorHandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                        UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                        bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		IsInside[Player] = true;


		if (IsBothPlayersInside())
			OpenBackDoors();
	}


	UFUNCTION()
	private void OpenBackDoors()
	{
		PrintToScreen("INSIIIDIE", 2.0);
		BackDoorTimeLike.Play();
	}

	UFUNCTION()
	private void BackDoorTimeLikeAnimUpdate(float CurrentValue)
	{
		BackRightDoorPivot.RelativeScale3D = FVector(1.0, 1.0, CurrentValue * 0.1);
		BackLeftDoorPivot.RelativeScale3D = FVector(1.0, 1.0, CurrentValue * 0.1);
	}

	UFUNCTION()
	private void FrontDoorTimeLikeFinished()
	{
		TimeToGoUp();
	}

	UFUNCTION()
	private void FrontDoorTimeLikeAnimUpdate(float CurrentValue)
	{
		FrontRightDoorPivot.RelativeScale3D = FVector(1.0, 1.0, CurrentValue * 31);
		FrontLeftDoorPivot.RelativeScale3D = FVector(1.0, 1.0, CurrentValue * 31);
	}

	UFUNCTION()
	private void FrontDoorHandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		IsInside[Player] = true;


		if (IsBothPlayersInside())
			CloseDoorsFrontDoors();
	}



	UFUNCTION()
	private void FrantDoorHandleEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		IsInside[Player] = false;

		OpenFrontDoors();
	}

	void CloseDoorsFrontDoors()
	{
		if(!bHasGoneUp)
			FrontDoorTimeLike.Play();
		USkylineBulwarkElevatorEventHandler::Trigger_OnDoorClose(this);
	}

	void OpenFrontDoors()
	{
		if(!bHasGoneUp)
		FrontDoorTimeLike.Reverse();
	}

		bool IsBothPlayersInside()
	{
		for (auto Player : Game::Players)
		{
			if (!IsInside[Player])
				return false;
		}

		return true;
	}



	UFUNCTION()
	private void HandleAnimFinished()
	{
		
		USkylineBulwarkElevatorEventHandler::Trigger_OnElevatorArrive(this);
	}

	UFUNCTION()
	private void AnimUpdate(float Value)
	{
		ElevatorRoot.RelativeLocation = FVector(0.0, 0.0, Value * 7005);
	}

	UFUNCTION(BlueprintCallable)
	private void TimeToGoUp()
	{
		if(!FrontDoorTimeLike.IsReversed())
			{
				ElevatorUpTimeLike.Play();
				bHasGoneUp = true;
				USkylineBulwarkElevatorEventHandler::Trigger_OnElevatorStart(this);
			}
	}
};