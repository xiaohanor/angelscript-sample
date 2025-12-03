class UAnimInstanceTundraEvergreenShootingPlantRoot : UHazeAnimInstanceBase
{
	AEvergreenShootingPlant Plant;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator Rotation;
	
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		Plant = Cast<AEvergreenShootingPlant>(HazeOwningActor);
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Plant == nullptr)
			return;

		Rotation = Plant.AnimationGetRotation();
		Rotation = FRotator(Math::UnwindDegrees(Rotation.Pitch), Rotation.Yaw, Rotation.Roll);
		Rotation.Pitch /= 3;
	}
}