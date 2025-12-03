class UAnimInstancePigWorldAppleDoor : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Idle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Open;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bOpen = false;

	AHungryDoor DoorActor;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		DoorActor = Cast<AHungryDoor>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (DoorActor == nullptr)
			return;

		bOpen = DoorActor.bDoorOpened;
	}
}