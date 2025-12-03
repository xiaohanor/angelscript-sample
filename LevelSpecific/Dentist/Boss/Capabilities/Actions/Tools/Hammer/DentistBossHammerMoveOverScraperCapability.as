struct FDentistBossHammerMoveOverScraperActivationParams
{
	float MoveDuration;
}

class UDentistBossHammerMoveOverScraperCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossToolHammer Hammer;
	ADentistBossToolScraper Scraper;

	FDentistBossHammerMoveOverScraperActivationParams Params;

	UDentistBossSettings Settings;

	FVector StartLocation;
	FRotator StartRotation;

	const float TargetUpOffset = 500.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossHammerMoveOverScraperActivationParams InParams)
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

		Hammer = Cast<ADentistBossToolHammer>(Dentist.Tools[EDentistBossTool::Hammer]);
		Scraper = Cast<ADentistBossToolScraper>(Dentist.Tools[EDentistBossTool::Scraper]);

		StartLocation = Hammer.ActorLocation;
		StartRotation = Hammer.ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Hammer.ActorLocation = GetTargetLocation();
		Hammer.ActorRotation = GetTargetRotation();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Params.MoveDuration == 0)
			return;
			
		float Alpha = ActiveDuration / Params.MoveDuration;
		Alpha = Math::EaseOut(0.0, 1.0, Alpha, 2.0);

		if(Alpha < 1.0)
		{
			Hammer.ActorLocation = Math::Lerp(StartLocation, GetTargetLocation(), Alpha);
			Hammer.ActorRotation = Math::LerpShortestPath(StartRotation, GetTargetRotation(), Alpha);
		}
	}

	FVector GetTargetLocation() const 
	{
		return Scraper.ActorLocation + FVector::UpVector * TargetUpOffset;
	}

	FRotator GetTargetRotation() const
	{
		return FRotator::MakeFromXZ(Dentist.ActorRightVector.RotateAngleAxis(-45, FVector::UpVector), FVector::UpVector);
	}
};