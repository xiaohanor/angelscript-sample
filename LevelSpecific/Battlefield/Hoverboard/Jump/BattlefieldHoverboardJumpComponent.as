class UBattlefieldHoverboardJumpComponent : UActorComponent
{
	bool bWantToJump = false;
	bool bJumpInputConsumed = false;
	bool bAirborneFromJump = false;
	bool bJumped = false;

	bool bHasTouchedGroundSinceLastJump = false;

	float TimeLastBecameAirborne = 0.0;

	FVector LastGroundNormal = FVector::UpVector;

	UPlayerMovementComponent MoveComp;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	void ConsumeJumpInput()
	{
		bWantToJump = false;
		bJumpInputConsumed = true;
		bHasTouchedGroundSinceLastJump = false;
	}
};