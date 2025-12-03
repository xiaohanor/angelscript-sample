
class USanctuaryFlightBossTurnInPlaceCapability : UBasicAIMovementCapability
{	
	USimpleMovementData SlidingMovement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SlidingMovement = Cast<USimpleMovementData>(Movement);
	}

	UBaseMovementData SetupMovementData() override
	{
		return MoveComp.SetupSimpleMovementData();
	} 

	bool PrepareMove() override
	{
		return MoveComp.PrepareMove(SlidingMovement);
	}

	void ComposeMovement(float DeltaTime) override
	{	
		// Turn towards focus or direction of move
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, 5.0, DeltaTime, Movement);
		else  
			MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);
	}

	void ApplyCrumbSyncedMovement(FVector Velocity) override
	{
		Movement.ApplyCrumbSyncedRotationOnly();
	}
}
