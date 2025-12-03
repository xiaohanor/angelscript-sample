
// Must defer spawn and initialize Owner property
class ASanctuaryGrimbeastMortarPool : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;

	bool bWasInPool = false;

	USanctuaryGrimbeastSettings Settings;
	AHazeActor Owner;
	float SpawnTime;
	float DamageTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = USanctuaryGrimbeastSettings::GetSettings(Owner);
		SpawnTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Time::GetGameTimeSince(SpawnTime) > Settings.MortarPoolLifetime)
		{
			DestroyActor();
			return;
		}

		if(DamageTime == 0 || Time::GetGameTimeSince(DamageTime) > Settings.MortarPoolCheckOverlapInterval)
		{
			bool bIsInPool = false;
			FVector InPoolLocation;
			for(FVector Location: GetTailLocations())
			{
				if(Location.IsWithinDist(ActorLocation, Settings.MortarPoolDamageDistance))
				{
					bIsInPool = true;
					InPoolLocation = Location;
					// USanctuaryGrimbeastMortarPoolEventHandler::Trigger_OnHitPlayer(this, FSanctuaryGrimbeastMortarPoolOnHitPlayerEventData(Game::Mio));
					// USanctuaryGrimbeastMortarPoolEventHandler::Trigger_OnHitPlayer(this, FSanctuaryGrimbeastMortarPoolOnHitPlayerEventData(Game::Zoe));
					break;
				}
			}			
			DamageTime = Time::GetGameTimeSeconds();

			// Since we're not using this class I just comment this out.
			// ManualStartOverlap over duration isn't supported anymore. We use OverlapSingleFrame now

			// if (bIsInPool && !bWasInPool)
			// 	LavaComp.ManualStartOverlap(InPoolLocation, Settings.MortarPoolDamageDistance, true);
			// else if (!bIsInPool && bWasInPool)
			// 	LavaComp.ManualEndOverlapWholeCentipedeApply();
			// bWasInPool = bIsInPool;
		}
	}

	private TArray<FVector> GetTailLocations() const
	{
		TArray<FVector> Locations;
		UPlayerCentipedeComponent CentipedeComp = UPlayerCentipedeComponent::Get(Game::Mio);
		if(ensure(CentipedeComp != nullptr, "Can only target centipede players!"))
			Locations = CentipedeComp.GetBodyLocations();
		return Locations;
	}
}