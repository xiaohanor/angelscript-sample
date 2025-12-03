asset FairyShapeshiftProxySettings of UPlayerDefaultProxyEmitterActivationSettings
{
	CameraDistanceActivationBufferDistance = 200;
}

class UTundraFairyShapeshiftAudioCapability : UTundraShapeshiftingAudioCapabilityBase
{
	default ShapeshiftShape = ETundraShapeshiftActiveShape::Small;

	UPROPERTY(EditDefaultsOnly, Category = "Crawl")
	UAudioPlayerFootTraceSettings CrawlFootTraceSettings;

	UTundraPlayerFairyCrawlComponent CrawlComp;
	bool bWasCrawling = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		CrawlComp = UTundraPlayerFairyCrawlComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Player.ApplySettings(FairyShapeshiftProxySettings, this, EHazeSettingsPriority::Override);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsWithAsset(FairyShapeshiftProxySettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if(CrawlComp.bIsInCrawl && !bWasCrawling)
		{
			Player.ApplySettings(CrawlFootTraceSettings, this);		

		}
		else if(!CrawlComp.bIsInCrawl && bWasCrawling)
		{
			Player.ClearSettingsWithAsset(CrawlFootTraceSettings, this);
		}

		bWasCrawling = CrawlComp.bIsInCrawl;	
	}
}