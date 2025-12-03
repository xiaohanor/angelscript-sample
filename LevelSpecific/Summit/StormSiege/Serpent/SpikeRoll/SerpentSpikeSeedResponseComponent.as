event void FOnSerpentSpikeSeedImpact();

class USerpentSpikeSeedResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnSerpentSpikeSeedImpact OnSerpentSpikeSeedImpact;
	
	void ActivateSpikeSeedHit()
	{
		OnSerpentSpikeSeedImpact.Broadcast();
	}
};