struct FSkylineDraggableGrappleLaunchConstrainHit
{
	float HitStrength = 0.0;
}

UCLASS(Abstract)
class USkylineDraggableGrappleLaunchEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnConstrainHitLowAlpha(FSkylineDraggableGrappleLaunchConstrainHit HitStrength) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnConstrainHitHighAlpha(FSkylineDraggableGrappleLaunchConstrainHit HitStrength) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityWhipGrabbed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityWhipReleased() {}	
}