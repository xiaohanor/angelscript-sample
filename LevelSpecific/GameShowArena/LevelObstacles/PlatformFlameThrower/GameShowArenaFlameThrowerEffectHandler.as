struct FGameShowArenaFlameThrowerActivationParams
{
	UPROPERTY()
	AGameShowArenaFlameThrower FlameThrower;
}

struct FGameShowArenaFlameThrowerDeactivationParams
{
	UPROPERTY()
	AGameShowArenaFlameThrower FlameThrower;
}

struct FGameShowArenaFlameThrowerBurnPlayerParams
{
	UPROPERTY()
	AGameShowArenaFlameThrower FlameThrower;
}

UCLASS()
class UGameShowArenaFlameThrowerEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFlamesActivated(FGameShowArenaFlameThrowerActivationParams Params)
	{
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHeatPlatform()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFlamesDeactivated(FGameShowArenaFlameThrowerDeactivationParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFlamesBurnPlayer(FGameShowArenaFlameThrowerBurnPlayerParams Params)
	{
	}
};