UCLASS(Abstract)
class UExplosiveSwingPointEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerKilled(FExplosiveSwingPointParams Params) {}
}

struct FExplosiveSwingPointParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}