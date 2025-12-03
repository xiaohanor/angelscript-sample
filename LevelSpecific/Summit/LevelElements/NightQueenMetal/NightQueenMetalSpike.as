event void FNightQueenMetalSpikeSignature();

class ANightQueenMetalSpike : ANightQueenMetal
{
	default BlockingVolume.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BlockingVolume.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	// default TimeBeforeStartingGrowth = 12.5;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USummitDeathVolumeComponent DeathComp;
	
	UPROPERTY()
	FNightQueenMetalSpikeSignature OnMelted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		ApplyDefaultSettings(NightQueenMetalSpikeMeltingSettings);

		OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		OnNightQueenMetalRecovered.AddUFunction(this, n"OnNightQueenMetalRecovered");
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		DeathComp.SetKillActive(false);
		OnMelted.Broadcast();
	}

	UFUNCTION()
	private void OnNightQueenMetalRecovered()
	{
		DeathComp.SetKillActive(true);
	}
}

asset NightQueenMetalSpikeMeltingSettings of UNightQueenMetalMeltingSettings
{
	MeltingSpeed = 8.0;
	
	Health = 2;
}
