class USkylineHighwayVehicleWhippableScanComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	EHazeSelectPlayer Select;

	bool bEnabled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DisableScan();
	}

	void EnableScan()
	{
		bEnabled = true;
		SetVisibility(true, true);
	}

	void DisableScan()
	{
		bEnabled = false;
		SetVisibility(false, true);
	}
}