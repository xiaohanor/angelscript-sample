UCLASS(Abstract)
class UAnimInstancePrisonPinballPlunger : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	APinballPlunger Plunger;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float PlungerDistance = 0;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Plunger = Cast<APinballPlunger>(HazeOwningActor);
    }

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(Plunger == nullptr)
			return;

		PlungerDistance = Plunger.GetPlungerOffset();
    }
};