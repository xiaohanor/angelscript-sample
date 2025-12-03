struct FSkylineHighwaySplineCraneConstrainHit
{
	float HitStrength = 0.0;
}

UCLASS(Abstract)
class USkylineHighwaySplineCraneEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnConstrainHitLowAlpha(FSkylineHighwaySplineCraneConstrainHit HitStrength) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnConstrainHitHighAlpha(FSkylineHighwaySplineCraneConstrainHit HitStrength) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityWhipGrabbed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityWhipReleased() {}	
}