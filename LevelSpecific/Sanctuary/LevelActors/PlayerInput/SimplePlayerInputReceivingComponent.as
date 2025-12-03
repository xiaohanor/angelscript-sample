class USimplePlayerInputReceivingComponenent : UHazeCapabilityComponent
{
	default DefaultCapabilities.Add(n"SimplePlayerInputReceivingCapability");

	UPROPERTY(EditAnywhere)
	EHazePlayer PlayerInput;

	UPROPERTY(EditAnywhere)
	bool bUseMovementRaw;

	FVector2D Input;

	UFUNCTION(BlueprintPure)
	FVector GetInputVector() const
	{
		FVector Vector;
		Vector.X = Input.Y;
		Vector.Y = Input.X;

		return Vector;
	}
}