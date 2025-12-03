class UTundra_SimonSaysMonkeyKingMovementComponent : UHazeMovementComponent
{
	// All of this is copied from the player movement component because it didn't exist in UHazeMovementComponent for some reason.

	protected FQuat PreviousFrameMovementRotation;
	protected float RelativeMovementYawVelocity = 0.0;
	protected float WorldMovementYawVelocity = 0.0;

	void PostResolve(UBaseMovementData DataType) override
	{
		Super::PostResolve(DataType);
		
		RelativeMovementYawVelocity = DataType.GetYawVelocityPostMovement(PreviousFrameMovementRotation, bRelativeToFollow = true);
		WorldMovementYawVelocity = DataType.GetYawVelocityPostMovement(PreviousFrameMovementRotation, bRelativeToFollow = false);
		PreviousFrameMovementRotation = HazeOwner.ActorQuat;
	}

	UFUNCTION(BlueprintOverride)
	void OnReset(FVector NewWorldUp, bool bValidateGround, float OverrideTraceDistance)
	{
		Super::OnReset(NewWorldUp, bValidateGround, OverrideTraceDistance);
		
		RelativeMovementYawVelocity = 0.0;
		WorldMovementYawVelocity = 0.0;
		PreviousFrameMovementRotation = HazeOwner.ActorQuat;
	}

	/**
	 * Get the angular velocity (degrees) of yaw that the player is exhibiting.
	 * Used for banking in animation, for example.
	 */
	float GetMovementYawVelocity(bool bRelativeToFloor) const
	{
		if (bRelativeToFloor)
			return RelativeMovementYawVelocity;
		else
			return WorldMovementYawVelocity;
	}
}