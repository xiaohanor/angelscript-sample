UCLASS(Abstract)
class UIslandWalkerNeckEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDestroyed(FIslandWalkerNeckDestroyedData Data) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGrenadeAttachedCorrect(){}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGrenadeAttachedWrongColour(){}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnForcefieldDepleted(){}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGrenadeDetonatedWrongColour(){}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPowerUp(){}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPowerDown(){}
}

struct FIslandWalkerNeckDestroyedData
{
	UPROPERTY()
	FVector Location;

	FIslandWalkerNeckDestroyedData(FVector InLocation)
	{
		Location = InLocation;
	}
}


