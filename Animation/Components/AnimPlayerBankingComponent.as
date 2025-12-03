class UHazeAnimPlayerBankingComponent : UHazeAnimBankingComponent
{
	private UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	float GetYawVelocity(float DeltaTime)
	{
		if (MoveComp != nullptr)
			return MoveComp.GetMovementYawVelocity(true);

		return 0;
	}
}