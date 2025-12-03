UCLASS(Abstract)
class UDentistSplitToothAIAnimInstance : UHazeAnimInstanceBase
{
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFalling;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGrounded;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFlail;

	ADentistSplitToothAI SplitToothAI;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if(HazeOwningActor == nullptr)
			return;

		SplitToothAI = Cast<ADentistSplitToothAI>(HazeOwningActor);
		MoveComp = SplitToothAI.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(MoveComp == nullptr)
			return;

		bJump = MoveComp.NewStateIsInAir();
		bIsFalling = MoveComp.IsFalling();
		bIsGrounded = MoveComp.IsOnAnyGround();
		bFlail = ShouldFlail();
	}

	bool ShouldFlail() const
	{
		if(SplitToothAI.State == EDentistSplitToothAIState::Splitting)
			return true;

		if(SplitToothAI.State == EDentistSplitToothAIState::Startled)
			return true;

		if(SplitToothAI.State == EDentistSplitToothAIState::Recombining)
			return true;

		return false;
	}
};