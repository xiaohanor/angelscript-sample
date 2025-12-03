struct FGameShowArenaLaunchPadLaunchParams
{
	UPROPERTY()
	AGameShowArenaLaunchPad LaunchPad;
}

struct FGameShowArenaFinalLaunchPadParams
{
	UPROPERTY()
	float TimeBetweenPlayerLaunches;
}

UCLASS()
class UGameShowArenaLaunchPadEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(FGameShowArenaLaunchPadLaunchParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartCharging(FGameShowArenaLaunchPadLaunchParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FullyCharged(FGameShowArenaLaunchPadLaunchParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinalLaunchpadBothPlayersLaunched(FGameShowArenaFinalLaunchPadParams Params)
	{
	}
};