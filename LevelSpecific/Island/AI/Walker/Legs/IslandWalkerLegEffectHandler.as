UCLASS(Abstract)
class UIslandWalkerLegEffectHandler : UHazeEffectEventHandler
{
	// The leg was destroyed
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDestroyed(FIslandWalkerLegDestroyedData Data) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGrenadeAttachedCorrect(){}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGrenadeAttachedWrongColour(){}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnForcefieldDepleted(){}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGrenadeDetonatedWrongColour(){}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnBluePanelOverload(FIslandWalkerPanelOverloadData Data){}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnRedPanelOverload(FIslandWalkerPanelOverloadData Data){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OpenLegCover(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void CloseLegCover(){}
}

struct FIslandWalkerLegDestroyedData
{
	UPROPERTY()
	FVector Location;

	FIslandWalkerLegDestroyedData(FVector InLocation)
	{
		Location = InLocation;
	}
}

struct FIslandWalkerPanelOverloadData
{
	UPROPERTY()
	USceneComponent PanelComp;

	FIslandWalkerPanelOverloadData(USceneComponent PanelComponent)
	{
		PanelComp = PanelComponent;
	}
}


