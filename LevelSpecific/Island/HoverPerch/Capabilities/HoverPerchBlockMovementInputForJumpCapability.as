struct FHoverPerchBlockMovementInputForJumpActivatedParams
{
	AHazePlayerCharacter Player;
}

class UHoverPerchBlockMovementInputForJumpCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 40;

	AHoverPerchActor PerchActor;
	AHazePlayerCharacter PlayerToBlockInputOn;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PerchActor = Cast<AHoverPerchActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHoverPerchBlockMovementInputForJumpActivatedParams& Params) const
	{
		if(PerchActor.HoverPerchComp.PerchingPlayer == nullptr)
			return false;

		if(PerchActor.HoverPerchComp.bIsDestroyed)
			return false;

		if(PerchActor.HoverPerchComp.bIsGrinding == false)
			return false;
		
		if(!WasActionStarted(ActionNames::MovementJump))
			return false;

		Params.Player = PerchActor.HoverPerchComp.PerchingPlayer;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PerchActor.HoverPerchComp.bIsGrinding == false)
			return true;

		if(PerchActor.HoverPerchComp.bIsDestroyed)
			return true;

		if(PerchActor.HoverPerchComp.PerchingPlayer == nullptr)
			return true;

		if(!PerchActor.PlayerIsJumping())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FHoverPerchBlockMovementInputForJumpActivatedParams Params)
	{
		PlayerToBlockInputOn = Params.Player;
		PlayerToBlockInputOn.ApplyMovementInput(FVector::ZeroVector, this, EInstigatePriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerToBlockInputOn.ClearMovementInput(this);
	}
};