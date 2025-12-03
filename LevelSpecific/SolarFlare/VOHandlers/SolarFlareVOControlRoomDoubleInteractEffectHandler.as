struct FSolarFlareVOControlRoomDoubleInteractStartedParams
{
	UPROPERTY()
	float WaitDuration = 5.0;

	UPROPERTY()
	AHazePlayerCharacter InteractingPlayer;
}

UCLASS(Abstract)
class USolarFlareVOControlRoomDoubleInteractEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoubleInteractStarted(FSolarFlareVOControlRoomDoubleInteractStartedParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoubleInteractCompleted()
	{
	}
};