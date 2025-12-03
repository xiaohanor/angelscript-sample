class UMoonMarketWandCrosshair : UCrosshairWidget
{
	bool bHasTarget = false;

	UFUNCTION(BlueprintEvent)
	void BP_OnShoot(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnTargetFound(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnTargetLost(){}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(bHasAutoAimTarget != bHasTarget)
		{
			bHasTarget = bHasAutoAimTarget;

			if(bHasTarget)
				BP_OnTargetFound();
			else
				BP_OnTargetLost();
		}
	}
}