
UCLASS(Abstract)
class UAnimInstanceAdultDragon : UHazeCharacterAnimInstance
{

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

	}


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{

	}


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{

	}
}