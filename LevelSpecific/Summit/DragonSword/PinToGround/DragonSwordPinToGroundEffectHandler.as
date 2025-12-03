struct FDragonSwordPinToGroundEnterParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
	UPROPERTY()
	FVector SwordLocation;
}

struct FDragonSwordPinToGroundExitParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
	UPROPERTY()
	FVector SwordLocation;
}

UCLASS()
class UDragonSwordPinToGroundEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPinToGroundEnter(FDragonSwordPinToGroundEnterParams EnterParams)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPinToGroundExit(FDragonSwordPinToGroundExitParams ExitParams)
	{
	}
};