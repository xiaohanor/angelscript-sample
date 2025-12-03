class ASoftSplitFantasyBridgeDestruction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Bridge;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent DetroyedBridge;

	FHazeTimeLike BridgeDestruction;
	default BridgeDestruction.Duration = 2.0;
	default BridgeDestruction.UseLinearCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BridgeDestruction.BindUpdate(this, n"UpdateBridge");
	}

	UFUNCTION()
	private void UpdateBridge(float CurrentValue)
	{
		DetroyedBridge.SetScalarParameterValueOnMaterialIndex(0, n"VAT_DisplayTime", CurrentValue);
	}

	UFUNCTION(BlueprintCallable)
	void DestroyBridge()
	{
		USoftSplitBridgeFantasyDestructionEventHandler::Trigger_DestroyFantasyBridge(this);	
		Bridge.SetHiddenInGame(true);
		BridgeDestruction.Play();
	}
	
};