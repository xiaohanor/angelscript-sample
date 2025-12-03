struct FSnowBallEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	FVector HitLocation;

	FSnowBallEventData(AHazePlayerCharacter _Player)
	{
		Player = _Player;
	}
}

UCLASS(Abstract)
class UTundra_River_SnowballEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSnowballThrow(FSnowBallEventData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSnowballHit(FSnowBallEventData Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSnowballHitGeo(FSnowBallEventData Params) {}
};