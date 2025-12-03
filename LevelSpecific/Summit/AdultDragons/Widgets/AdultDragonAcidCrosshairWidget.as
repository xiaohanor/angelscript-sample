class UAdultDragonAcidCrosshairWidget : UCrosshairWidget
{
	UPROPERTY(BindWidget)
	UImage Crosshair;

	UPlayerAimingComponent AimComp;
	UPlayerAcidAdultDragonComponent DragonComp;
	UAdultDragonAcidProjectileComponent ProjectileComp;

	bool bHadAimingTarget = false;
	bool bIsBeingRemoved = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerAcidAdultDragonComponent::Get(Player);
		ProjectileComp = UAdultDragonAcidProjectileComponent::Get(Player);
		ProjectileComp.OnProjectileFired.AddUFunction(this, n"BP_OnProjectileFired");
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnStartTargeting(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnStopTargeting(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnProjectileFired(){}

	UFUNCTION(BlueprintOverride)
	void OnCrosshairFadingOut()
	{
		Super::OnCrosshairFadingOut();
		bIsBeingRemoved = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(!AimComp.IsAiming(Player))
		{
			if (!bIsBeingRemoved)
				PrintError("Aiming not started with instigator " + Player + ", change aim instigator in AdultDragonAcidCrosshairWidget");
			
			return;
		}

		if(AimComp.GetAimingTarget(Player).AutoAimTarget != nullptr)
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
}