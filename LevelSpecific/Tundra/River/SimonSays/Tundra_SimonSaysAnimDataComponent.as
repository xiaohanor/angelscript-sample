struct FTundra_SimonSaysAnimData
{
	// Degrees per second, positive is clockwise/negative is counter clockwise.
	float CurrentTurnRate = 0.0;

	// Is true if we are currently jumping
	bool bIsJumping = false;

	// True for players that are currently standing on a tile that is falling down.
	bool bIsFalling = false;

	// True for players and monkey king when the players succeed with their turn.
	bool bIsSuccess = false;

	// True for both players and monkey king when the players fail their turn.
	bool bIsFail = false;
}

class UTundra_SimonSaysAnimDataComponent : UActorComponent
{
	FTundra_SimonSaysAnimData AnimData;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this)
		.Value("Current Turn Rate", AnimData.CurrentTurnRate)
		.Value("Is Jumping", AnimData.bIsJumping)
		.Value("Is Falling", AnimData.bIsFalling)
		.Value("Is Success", AnimData.bIsSuccess)
		.Value("Is Fail", AnimData.bIsFail);
	}
#endif

	void UpdateTurnRate(FVector PreviousForward, FVector CurrentForward, float DeltaTime)
	{
		float Dot = PreviousForward.DotProduct(CurrentForward);
		float Degrees = Math::DotToDegrees(Dot);
		float DegreesPerSecond = Degrees / DeltaTime;

		FVector PreviousRight = FVector::UpVector.CrossProduct(PreviousForward);
		float Sign = Math::Sign(PreviousRight.DotProduct(CurrentForward));
		AnimData.CurrentTurnRate = DegreesPerSecond * Sign;
	}
}