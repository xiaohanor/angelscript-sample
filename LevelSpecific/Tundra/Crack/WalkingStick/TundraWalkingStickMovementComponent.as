class UTundraWalkingStickMovementComponent : UHazeMovementComponent
{
	ATundraWalkingStick WalkingStick;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		WalkingStick = Cast<ATundraWalkingStick>(Owner);
	}

	void ApplyMoveAndRequestLocomotion(UBaseMovementData Movement, FName AnimationTag)
	{
		ApplyMove(Movement);
		if(WalkingStick.Mesh.CanRequestLocomotion())
		{
			WalkingStick.Mesh.RequestLocomotion(AnimationTag, this);
		}
	}
}