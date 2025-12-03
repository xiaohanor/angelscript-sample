UCLASS(Abstract)
class UFeatureAnimInstanceRootElevator : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayBlendSpaceData RootElevator;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Weight = -0.2;

	ATundraCrackRootElevator Elevator;
	ATundraCrackRootMonkeyHanger MonkeyHanger;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		Elevator = Cast<ATundraCrackRootElevator>(HazeOwningActor);
		MonkeyHanger = Cast<ATundraCrackRootMonkeyHanger>(HazeOwningActor);

	if(Elevator != nullptr)
		Weight = -0.2;
	else if(MonkeyHanger != nullptr)
		Weight = 0;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(HazeOwningActor == nullptr)
			return;

		if(Elevator != nullptr)
			Weight = Elevator.AnimData.VerticalAlpha;
		else if(MonkeyHanger != nullptr)
			Weight = MonkeyHanger.AnimData.VerticalAlpha;
	}
}

