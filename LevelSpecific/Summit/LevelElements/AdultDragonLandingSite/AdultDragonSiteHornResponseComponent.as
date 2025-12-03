event void FOnAdultDragonSiteHornCompleted(FVector HornCenterLocation = FVector(0.0));

class UAdultDragonSiteHornResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnAdultDragonSiteHornCompleted OnAdultDragonSiteHornCompleted;

	UPROPERTY(EditAnywhere)
	AAdultDragonLandingSite LandingSite1;
	UPROPERTY(EditAnywhere)
	AAdultDragonLandingSite LandingSite2;

	bool bHornBlown;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LandingSite1.OnBlowHorn.AddUFunction(this, n"OnBlowHorn");
		LandingSite2.OnBlowHorn.AddUFunction(this, n"OnBlowHorn");
	}

	UFUNCTION()
	private void OnBlowHorn()
	{
		if (LandingSite1.HornBlowAvailable() || LandingSite2.HornBlowAvailable())
			return;

		if (bHornBlown)
			return;

		FVector CentralLocation = (LandingSite1.ActorLocation + LandingSite2.ActorLocation) / 2;

		bHornBlown = true;
		OnAdultDragonSiteHornCompleted.Broadcast(CentralLocation);
	}
}