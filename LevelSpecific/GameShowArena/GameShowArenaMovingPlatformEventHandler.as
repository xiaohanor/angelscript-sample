struct FGameShowArenaMovingPlatformMovingStartedParams
{
	UPROPERTY()
	AGameShowArenaMovingPlatform MovingPlatform;
}

struct FGameShowArenaMovingPlatformMovingStoppedParams
{
	UPROPERTY()
	AGameShowArenaMovingPlatform MovingPlatform;
}

UCLASS(Abstract)
class UGameShowArenaMovingPlatformEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMoving(FGameShowArenaMovingPlatformMovingStartedParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMoving(FGameShowArenaMovingPlatformMovingStoppedParams Params)
	{
	}
};