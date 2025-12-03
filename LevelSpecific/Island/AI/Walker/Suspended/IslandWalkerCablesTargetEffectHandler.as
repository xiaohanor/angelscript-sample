UCLASS(Abstract)
class UIslandWalkerCablesTargetEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, Transient, NotVisible)
	AIslandWalkerCablesTarget CablesTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CablesTarget = Cast<AIslandWalkerCablesTarget>(Owner);		
	}
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDestroyed(FIslandWalkerCablesTargetDestroyedData Data) {}

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

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGrenadeRemovedCorreect(){}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGrenadeRemovedWrongColour(){}
}

struct FIslandWalkerCablesTargetDestroyedData
{
	UPROPERTY()
	FVector Location;

	FIslandWalkerCablesTargetDestroyedData(FVector InLocation)
	{
		Location = InLocation;
	}
}
