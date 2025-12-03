class AIslandOverseerCrane : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftClaw;

	UPROPERTY(DefaultComponent)
	USceneComponent RightClaw;

	FVector Velocity;
	FVector PreviousLocation;
	bool WasMoving;
	bool bIsVisible;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIsVisible)
			return;

		if(PreviousLocation == FVector::ZeroVector)
			PreviousLocation = ActorLocation;
		Velocity = ActorLocation - PreviousLocation;
		PreviousLocation = ActorLocation;
		
		if(!Velocity.IsNearlyZero(.01) && !WasMoving)
		{
			WasMoving = true;
			UIslandOverseerCraneEventHandler::Trigger_OnMoveStart(this);
		}
		else if(Velocity.IsNearlyZero(0.01) && WasMoving)
		{
			WasMoving = false;
			UIslandOverseerCraneEventHandler::Trigger_OnMoveStop(this);
		}
	}
}