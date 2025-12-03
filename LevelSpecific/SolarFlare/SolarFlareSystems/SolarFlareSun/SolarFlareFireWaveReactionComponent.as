event void FOnSolarFlareImpact(); 
event void FOnSolarPreFlareImpact(); 

class USolarFlareFireWaveReactionComponent : UActorComponent
{
	UPROPERTY()
	FOnSolarFlareImpact OnSolarFlareImpact;
	UPROPERTY()
	FOnSolarPreFlareImpact OnSolarPreFlareImpact;
	
	ASolarFlareSun Sun;
	ASolarFlareFireDonutActor SolarFlareDonutWave;

	private bool bNewActive;
	private bool bNewPreActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Sun == nullptr)
		{
			Sun = TListedActors<ASolarFlareSun>().GetSingle();
			Sun.ReactionComps.Add(this);
		}
	}

	void RunPreBroadcastCheck()
	{
		if (bNewPreActive)
		{
			bNewPreActive = false;
			OnSolarPreFlareImpact.Broadcast();
		}
	}

	void RunBroadcastCheck()
	{
		if (bNewActive)
		{
			bNewActive = false;
			OnSolarFlareImpact.Broadcast();
		}
	}

	void SolarFlareFireDonutActivated()
	{
		bNewActive = true;
		bNewPreActive = true;
	}

	UFUNCTION()
	private void OnSolarFlareNewFlareCreated(ASolarFlareFireDonutActor NewDonut)
	{
		SolarFlareDonutWave = NewDonut;
	}
}