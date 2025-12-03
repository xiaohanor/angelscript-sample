UCLASS(Abstract)
class USkylineInnerCityBikeShopDoorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorOpen()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorClose()
	{
	}

};	
class ASkylineInnerCityBikeShopDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	FHazeTimeLike DoorTimeLike;

	UPROPERTY(DefaultComponent)
	USceneComponent Door;
	UPROPERTY(DefaultComponent, Attach = Door)
	USceneComponent LeftDoorPivot;
	UPROPERTY(DefaultComponent, Attach = Door)
	USceneComponent RightDoorPivot;

	TPerPlayer<bool> IsInside;

	UPROPERTY(DefaultComponent)
	UBoxComponent DoorTrigger;
	default DoorTrigger.BoxExtent = FVector::OneVector * 100.0;
	default DoorTrigger.bGenerateOverlapEvents = true;
	default DoorTrigger.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default DoorTrigger.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoorTimeLike.BindUpdate(this, n"DoorTimeLikeAnimUpdate");
	
		DoorTrigger.OnComponentBeginOverlap.AddUFunction(this, n"DoorHandleBeginOverlap");
		DoorTrigger.OnComponentEndOverlap.AddUFunction(this, n"DoorHandleEndOverlap");
	}

	UFUNCTION()
	private void DoorTimeLikeAnimUpdate(float CurrentValue)
	{
		RightDoorPivot.RelativeLocation = FVector(0.0, 200 * CurrentValue, 0.0);
		LeftDoorPivot.RelativeLocation = FVector(0.0, -200 * CurrentValue, 0.0);
	}

	UFUNCTION()
	private void DoorHandleEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                  UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		IsInside[Player] = false;

		if (!IsInside[Player.OtherPlayer])
		CloseDoors();	
	}

	UFUNCTION()
	private void DoorHandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                    UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                    bool bFromSweep, const FHitResult&in SweepResult)
	{
			auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		IsInside[Player] = true;


			OpenDoors();
	}

	UFUNCTION()
	private void OpenDoors()
	{
		DoorTimeLike.Play();
		BP_LightUp();
		USkylineInnerCityBikeShopDoorEventHandler::Trigger_OnDoorOpen(this);
	}
	
	void BP_LightUp()
	{
	}

	UFUNCTION()
	private void CloseDoors()
	{
		USkylineInnerCityBikeShopDoorEventHandler::Trigger_OnDoorClose(this);
		DoorTimeLike.Reverse();
		BP_LightOff();
	}

	UFUNCTION(BlueprintEvent)
	void BP_LightOff()
	{
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
};