UCLASS(Abstract)
class UFeatureAnimInstanceDesertDropShip : UHazeAnimInstanceBase
{	
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D MovementBSValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsHovering;

	AControllableDropShip DropShip;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		DropShip = Cast<AControllableDropShip>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (DropShip == nullptr)
			return;

		MovementBSValues = DropShip.FlyValues;
		bIsHovering = DropShip.bHovering;
	}
}

