class AMeltdownWorldSpinRaderBridgeDestroy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent VatBridge01;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent VatBridge02;

	FHazeTimeLike VatDestroy;
	default VatDestroy.Duration = 3.0;
	default VatDestroy.UseLinearCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VatDestroy.BindUpdate(this, n"UpdateBridge");
	}

	UFUNCTION()
	private void UpdateBridge(float CurrentValue)
	{
		VatBridge01.SetScalarParameterValueOnMaterials(n"VAT_DisplayTime", Math::Lerp(0,1,CurrentValue));
		VatBridge02.SetScalarParameterValueOnMaterials(n"VAT_DisplayTime", Math::Lerp(0,1,CurrentValue));
	}

	UFUNCTION()
	void DestroyBridge()
	{
		UMeltdownWorldSpinBridgeDestroyEventHandler::Trigger_BridgeDestruction(this);
		VatDestroy.PlayFromStart();
	}
};