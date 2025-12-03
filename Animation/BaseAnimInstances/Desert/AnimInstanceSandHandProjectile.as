class UAnimInstanceSandHandProjectile : UHazeAnimInstanceBase
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsAimingAtTarget;

	ASandHandProjectile SandHand;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		SandHand = Cast<ASandHandProjectile>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (SandHand == nullptr)
			return;

		bIsAimingAtTarget = SandHand.bIsAimingAtTarget;
	}
}