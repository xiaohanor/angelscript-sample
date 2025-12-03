class USummitMountainBirdEventHandler : UHazeEffectEventHandler
{	
	// This will usually happen at the same time as a take off.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerTooClose() {}

	// Note that bird might take off even if a player is not close by. If a player is close though, she likely triggered the take off.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTakeOff() {}

	// After Take Off has reched the desired height, this event is triggered when starting to fly around in loops.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHoveringStart() {}

	// Starting descend for landing.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))	
	void OnLandingStart() {}

	// Starting the break flapping of wings before touching ground.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))	
	void OnLandingBreakForGroundImpact() {}

	// Finish landing when touching ground.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))	
	void OnLandingFinished() {}
}