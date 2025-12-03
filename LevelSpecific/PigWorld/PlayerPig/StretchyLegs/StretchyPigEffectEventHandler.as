
UCLASS(Abstract)
class UStretchyPigEffectEventHandler : UHazeEffectEventHandler
{
	// Called when the player starts stretching
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStretchStart() {}

	// Pig is fully stretched
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyStretched() {}

	// Called when the player deactivates the stretch to jump
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStretchJump() {}


	// Stretching got interrupted by hitting something, will now become dizzy
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStretchInterrupted() {}


	// Called when the player is hitting head in ceiling and getting dizzeh
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDizzyStart() {}

	// Called when the player stops being dizzy after hitting head
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDizzyStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlideStarted(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlideStopped(){}
}