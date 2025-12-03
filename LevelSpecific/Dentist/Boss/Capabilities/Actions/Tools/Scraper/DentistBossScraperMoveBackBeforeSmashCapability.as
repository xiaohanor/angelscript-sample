struct FDentistBossScraperMoveBackBeforeSmashActivationParams
{
	float MoveDuration;
}

class UDentistBossScraperMoveBackBeforeSmashCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossToolScraper Scraper;
	
	FDentistBossScraperMoveBackBeforeSmashActivationParams Params;

	UDentistBossSettings Settings;

	FVector StartLocation;
	FRotator StartRotation;

	const float TargetForwardOffset = 700.0;
	const float TargetUpOffset = 150.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossScraperMoveBackBeforeSmashActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Params.MoveDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

		auto Tool = Dentist.Tools[EDentistBossTool::Scraper];
		Scraper = Cast<ADentistBossToolScraper>(Tool);

		StartLocation = Scraper.ActorLocation;
		StartRotation = Scraper.ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Scraper.ActorLocation = GetTargetLocation();
		Scraper.ActorRotation = GetTargetRotation();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Params.MoveDuration == 0)
			return;
			
		float Alpha = ActiveDuration / Params.MoveDuration;

		if(Alpha < 1.0)
		{
			Scraper.ActorLocation = Math::Lerp(StartLocation, GetTargetLocation(), Alpha);
			Scraper.ActorRotation = Math::LerpShortestPath(StartRotation, GetTargetRotation(), Alpha);
		}
	}

	FVector GetTargetLocation() const 
	{
		return Dentist.Cake.ActorLocation 
			- Dentist.Cake.ActorRightVector * TargetForwardOffset
			+ FVector::UpVector * TargetUpOffset;
	}

	FRotator GetTargetRotation() const
	{
		return FRotator::MakeFromXZ(Dentist.ActorRightVector.RotateAngleAxis(45, FVector::UpVector), FVector::UpVector);
	}
};