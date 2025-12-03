class UAnimInstanceSanctuaryGhost : UHazeAnimInstanceBase
{
	ASanctuaryGhost Ghost;

	UPROPERTY()
	bool bIsChasing = false;

	UPROPERTY()
	bool bIsAttacking = false;

	UPROPERTY()
	bool bIsIlluminated = false;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor != nullptr)
			Ghost = Cast<ASanctuaryGhost>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HazeOwningActor == nullptr)
			return;

		bIsChasing = Ghost.bIsChasing;
		bIsAttacking = Ghost.bIsAttacking;
		bIsIlluminated = Ghost.bIsIlluminated;
	}
}