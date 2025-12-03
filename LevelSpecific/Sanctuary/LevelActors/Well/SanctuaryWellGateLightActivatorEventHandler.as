UCLASS(Abstract)
class USanctuaryWellGateLightActivatorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SocketGrabbedMovingTowardsDoor() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SocketReleasedMovingToStartPosition() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SocketReturnedToStartPosition() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SocketInDoor() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartedActivation() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BothAbilitiesActivatedSuccess() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LightProgressTimeLikeFinished() {}
};