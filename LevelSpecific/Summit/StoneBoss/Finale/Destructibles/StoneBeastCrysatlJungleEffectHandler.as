struct FOnStoneBeastCrystalJungleParams
{
	UPROPERTY()
	FVector Location;

	FOnStoneBeastCrystalJungleParams (FVector NewLoc)
	{
		Location = NewLoc;
	}
}

struct FOnStoneBeastCrystalJungleHitParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FVector Normal;

	FOnStoneBeastCrystalJungleHitParams (FVector NewLoc, FVector NewNormal)
	{
		Location = NewLoc;
		Normal = NewNormal;
	}
}

UCLASS(Abstract)
class UStoneBeastCrysatlJungleEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Destroyed(FOnStoneBeastCrystalJungleParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Hit(FOnStoneBeastCrystalJungleHitParams Params) {}
};