event void FOnStormSiegeBarrierTargetTriggered();

class UStormSiegeMagicBarrierResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnStormSiegeBarrierTargetTriggered OnStormSiegeMagicBarrierTargetTriggered;

	bool bHasTriggered;

	UFUNCTION()
	void TriggerTarget()
	{
		if (bHasTriggered)
			return;
		
		bHasTriggered = true;
		OnStormSiegeMagicBarrierTargetTriggered.Broadcast();
	} 
}