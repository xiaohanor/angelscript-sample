UCLASS(Abstract)
class UFlyingCarBazookaCrosshairWidget : UCrosshairWidget
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bAimingDownSights;

	private USkylineFlyingCarGunnerComponent GunnerComponent;

	UFUNCTION(BlueprintOverride)
	void OnInitialized()
	{
		GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Player);

		// Firing happens on same frame as reloading, gross but fair
		GunnerComponent.OnReloading.AddUFunction(this, n"OnFire");

		GunnerComponent.OnReloading.AddUFunction(this, n"OnReloading");
		GunnerComponent.OnReloaded.AddUFunction(this, n"OnReloaded");
	}

	void OnUpdateCrosshairContainer(float DeltaTime) override
	{
		Super::OnUpdateCrosshairContainer(DeltaTime);

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

	UFUNCTION(BlueprintEvent)
	private void OnFire() { }

	UFUNCTION(BlueprintEvent)
	private void OnReloading() { }

	UFUNCTION(BlueprintEvent)
	private void OnReloaded() { }

	UFUNCTION(BlueprintEvent)
	void OnAimDownSightsStarted() { }

	UFUNCTION(BlueprintEvent)
	void OnAimDownSightsStopped() { }
}