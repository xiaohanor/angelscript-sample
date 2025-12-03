struct FMoonMarketFollowBalloonPlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}


UCLASS(Abstract)
class UMoonMarketFollowBalloonEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBalloonTaken(FMoonMarketFollowBalloonPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBalloonReleased() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBalloonPopped() {}

	//For when the player is running with balloons, there will be a bit of a yanking motion instead of smooth follow
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBalloonYanked() {}

	//Mostly for when the balloon hits roofs
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBalloonCollide() {}
};