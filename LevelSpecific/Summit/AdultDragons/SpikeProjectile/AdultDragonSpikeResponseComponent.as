event void FOnSpikeHit();

class UAdultDragonSpikeResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnSpikeHit OnSpikeHit;

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbActivateSpikeHit()
	{
		OnSpikeHit.Broadcast();
	}
}