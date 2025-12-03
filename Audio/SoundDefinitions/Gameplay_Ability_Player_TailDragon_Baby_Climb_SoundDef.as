
UCLASS(Abstract)
class UGameplay_Ability_Player_TailDragon_Baby_Climb_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPlayerMovementComponent MoveComp;

	UPROPERTY(BlueprintReadOnly)
	UPlayerTailBabyDragonComponent DragonComp;

	UPROPERTY(BlueprintReadOnly)
	float StickInputDelta = 0.0;
	private FVector PreviousStickInput;
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SetPlayerOwner(Game::GetZoe());
		DragonComp = UPlayerTailBabyDragonComponent::Get(PlayerOwner);
		MoveComp = UPlayerMovementComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return DragonComp.ClimbState == ETailBabyDragonClimbState::Enter;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return DragonComp.ClimbState == ETailBabyDragonClimbState::None
		||	   DragonComp.ClimbState == ETailBabyDragonClimbState::Transfer;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector Input = MoveComp.GetSyncedMovementInputForAnimationOnly();

		StickInputDelta = (Input - PreviousStickInput).GetAbs().Size();
		PreviousStickInput = Input;
	}


}