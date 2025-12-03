UCLASS(Abstract)
class UFlyingCarRifleCrosshairWidget : UCrosshairWidget
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bAimingDownSights;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bShooting;

	USkylineFlyingCarGunnerComponent GunnerComponent;

	UFUNCTION(BlueprintOverride)
	void OnInitialized()
	{
		GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Player);

		GunnerComponent.OnReloading.AddUFunction(this, n"OnReloading");
		GunnerComponent.OnReloaded.AddUFunction(this, n"OnReloaded");
	}

	void OnUpdateCrosshairContainer(float DeltaTime) override
	{
		Super::OnUpdateCrosshairContainer(DeltaTime);

		// Check for firing
		bShooting = GunnerComponent.IsShooting();

		// Check for ADS
		{
			if (GunnerComponent.bIsInAimDown && !bAimingDownSights)
			{
				bAimingDownSights = true;
				OnAimDownSightsStarted();

			}
			else if (!GunnerComponent.bIsInAimDown && bAimingDownSights)
			{
				bAimingDownSights = false;
				OnAimDownSightsStopped();
			}
		}
	}


	// Reloading started
	UFUNCTION(BlueprintEvent)
	void OnReloading() { }

	// Reload complete
	UFUNCTION(BlueprintEvent)
	void OnReloaded() { }

	UFUNCTION(BlueprintEvent)
	void OnAimDownSightsStarted() { }

	UFUNCTION(BlueprintEvent)
	void OnAimDownSightsStopped() { }
}