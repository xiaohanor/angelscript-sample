UCLASS(Abstract)
class USplitTraversalCatWaterfallEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartPouring() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopPouring() {}
}

class ASplitTraversalCatWaterfall : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UNiagaraComponent WaterVFXComp;

	UPROPERTY()
	FVector WaterLocation;

	bool bDeactivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bDeactivated && WaterLocation.Z > 0.0)
		{
			bDeactivated = true;
			BP_DeactivateWater();
		}
	}

	void Activate()
	{
		BP_ActivateWater();
		USplitTraversalCatWaterfallEventHandler::Trigger_StartPouring(this);
	}

	void Deactivate()
	{
		BP_DeactivateWater();
		USplitTraversalCatWaterfallEventHandler::Trigger_StopPouring(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_ActivateWater(){}

	UFUNCTION(BlueprintEvent)
	private void BP_DeactivateWater(){}
};