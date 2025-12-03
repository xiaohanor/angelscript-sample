struct FStormKnightLightningParams
{
	UPROPERTY()
	FVector Start;

	UPROPERTY()
	FVector End;

	UPROPERTY()
	float Width;
}

UCLASS(Abstract)
class UStormKnightLightningAttackEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void LightningStrike(FStormKnightLightningParams Params) {}
}