class UTeenDragonAcidSprayCrosshairWidget : UCrosshairWidget
{
	UPROPERTY(BindWidget)
	UImage Crosshair;

	UPlayerAimingComponent AimComp;
	UPlayerAcidTeenDragonComponent DragonComp;

	bool bHadAimingTarget = false;
	bool bWasFiring = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnStartTargeting(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnStopTargeting(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnStartFiring(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnStopFiring(){}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(!AimComp.IsAiming(DragonComp))
		{
			if(bHadAimingTarget)
			{
				bHadAimingTarget = false;
				BP_OnStopTargeting();
			}
		}
		else
		{
			if(AimComp.GetAimingTarget(DragonComp).AutoAimTarget != nullptr || DragonComp.bIsAimingAtTarget)
			{
				if(!bHadAimingTarget)
				{
					bHadAimingTarget = true;
					BP_OnStartTargeting();
				}
			}
			else
			{
				if(bHadAimingTarget)
				{
					bHadAimingTarget = false;
					BP_OnStopTargeting();
				}
			}
		}

		if(DragonComp.bIsFiringAcid)
		{
			if(!bWasFiring)
			{
				BP_OnStartFiring();
				bWasFiring = true;
			}
		}
		else
		{
			if(bWasFiring)
			{
				BP_OnStopFiring();
				bWasFiring = false;
			}
		}
	}
}