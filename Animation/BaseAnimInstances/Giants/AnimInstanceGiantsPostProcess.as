class UAnimInstanceGiantsPostProcess : UAnimInstance
{
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bEnablePhysics;

	AHazeActor HazeOwningActor;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		HazeOwningActor = Cast<AHazeActor>(OwningComponent.GetOwner());
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		const auto Giant = Cast<ATheGiant>(HazeOwningActor);
		if (Giant != nullptr)
			bEnablePhysics = Giant.bEnablePhysics;
	}
}