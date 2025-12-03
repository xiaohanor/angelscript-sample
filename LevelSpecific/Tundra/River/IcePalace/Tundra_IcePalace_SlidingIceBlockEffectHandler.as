struct FTundra_IcePalace_SlidingIceBlockMoveEffectParams
{
	FTundra_IcePalace_SlidingIceBlockMoveEffectParams(FVector In_MoveDirection)
	{
		MoveDirection = In_MoveDirection;
	}

	UPROPERTY()
	FVector MoveDirection;
}

struct FTundra_IcePalace_SlidingIceBlockKillPlayerEffectParams
{
	FTundra_IcePalace_SlidingIceBlockKillPlayerEffectParams(AHazePlayerCharacter In_KilledPlayer)
	{
		KilledPlayer = In_KilledPlayer;
	}

	UPROPERTY()
	AHazePlayerCharacter KilledPlayer;
}

UCLASS(Abstract)
class UTundra_IcePalace_SlidingIceBlockEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartSlide(FTundra_IcePalace_SlidingIceBlockMoveEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpactOnOuterConstraint(FTundra_IcePalace_SlidingIceBlockMoveEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpactOnBlocker(FTundra_IcePalace_SlidingIceBlockMoveEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpactOnGate(FTundra_IcePalace_SlidingIceBlockMoveEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKillPlayer(FTundra_IcePalace_SlidingIceBlockKillPlayerEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMoveDownIntoGround() {}
}