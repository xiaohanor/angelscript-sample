struct FMoonMarketOnEnterBubbleEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
	UPROPERTY()
	FVector EnterLocation;
	UPROPERTY()
	FVector EnterVelocity;
}

struct FMoonMarketOnLeaveBubbleEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
	UPROPERTY()
	FVector LeaveLocation;
	UPROPERTY()
	FVector LeaveVelocity;
}


UCLASS(Abstract)
class UMoonMarketWaterBubbleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnterBubble(FMoonMarketOnEnterBubbleEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeaveBubble(FMoonMarketOnLeaveBubbleEventData Data) {}
};