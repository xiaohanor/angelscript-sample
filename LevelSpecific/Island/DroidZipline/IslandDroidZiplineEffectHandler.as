struct FIslandDroidZiplineOnImpactParams
{
	UPROPERTY()
	FVector DroidLocation;
}

struct FIslandDroidZiplineOnAttachParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class UIslandDroidZiplineEffectHandler : UHazeEffectEventHandler
{
	// Called when the drone dies from impacting ceiling/wall/ground
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeathImpact(FIslandDroidZiplineOnImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerAttach(FIslandDroidZiplineOnAttachParams Params) {}
}