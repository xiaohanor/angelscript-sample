UCLASS(Abstract)
class UTundraBossCrackingIce_EffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFurballExploded(FTundraBossCrackingIceEffectParams Params)
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIceDestroyed()
	{
		
	}
};

struct FTundraBossCrackingIceEffectParams
{
	UPROPERTY()
	FVector ExplosionLocation;

	UPROPERTY()
	bool bFurballWillExplodeIce;
}