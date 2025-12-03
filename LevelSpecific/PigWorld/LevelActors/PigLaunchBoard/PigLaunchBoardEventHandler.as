
struct FPigLaunchBoardFailedJumpEventHandlerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	int NumFailedJumps;
}

UCLASS(Abstract)
class UPigLaunchBoardEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmallLaunch() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BigLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BigLandingOnLaunchSide() {}

	// Called when the player is launched but not high enough
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FailedJump(FPigLaunchBoardFailedJumpEventHandlerParams EventParams) {}
}