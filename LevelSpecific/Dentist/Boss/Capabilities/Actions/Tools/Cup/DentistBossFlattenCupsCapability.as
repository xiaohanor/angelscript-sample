struct FDentistBossFlattenCupsActivationParams
{
	float FlattenDuration;
}

class UDentistBossFlattenCupsCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossCupManager CupManager;
	
	FDentistBossFlattenCupsActivationParams Params;
	UDentistBossSettings Settings;

	TArray<ADentistBossToolCup> CupsToSmash;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		CupManager = Dentist.CupManager;
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossFlattenCupsActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Params.FlattenDuration)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CupsToSmash.Reset();
		auto LeftCup = Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupLeft]);
		if(!LeftCup.bHasBeenOpened)
			CupsToSmash.Add(LeftCup);
		auto MiddleCup = Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupMiddle]);
		if(!MiddleCup.bHasBeenOpened)
			CupsToSmash.Add(MiddleCup);
		auto RightCup = Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupRight]);
		if(!RightCup.bHasBeenOpened)
			CupsToSmash.Add(RightCup);

		for(auto Cup : CupsToSmash)
		{
			Cup.bIsFlattened = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SetCupsScale(1.0);
		for(auto Cup : CupsToSmash)
		{
			Cup.BecomeFlattened();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / Params.FlattenDuration;

		SetCupsScale(Alpha);
	}

	void SetCupsScale(float Alpha)
	{
		const float ClampedAlpha = Math::Saturate(Alpha); 

		for(auto Cup : CupsToSmash)
		{
			FVector TargetLocation;
			if(Cup.ToolType == EDentistBossTool::CupLeft)
				TargetLocation = Dentist.Cake.ActorLocation + DentistBossMeasurements::LeftCupCakeRelativeLocation;
			else if(Cup.ToolType == EDentistBossTool::CupMiddle)
				TargetLocation = Dentist.Cake.ActorLocation + DentistBossMeasurements::MiddleCupCakeRelativeLocation;
			else
				TargetLocation = Dentist.Cake.ActorLocation + DentistBossMeasurements::RightCupCakeRelativeLocation;
			
			float NewZScale = Math::Lerp(1.0, Settings.CupSmashMinScale, ClampedAlpha);
			FVector NewScale = FVector(1.0, 1.0, Math::Clamp(NewZScale, KINDA_SMALL_NUMBER, BIG_NUMBER));
			Cup.MeshScaleRoot.SetWorldScale3D(NewScale);
			TargetLocation += FVector::DownVector * (DentistBossMeasurements::CupHeight * (1 - NewZScale));
			TEMPORAL_LOG(Cup)
				.Sphere("Target Location", TargetLocation, 50, FLinearColor::LucBlue, 10.0)
				.Value("New Z Scale", NewZScale)
				.Value("Alpha", Alpha)
				.Value("Clamped Alpha", ClampedAlpha)
			;
			Cup.SetActorLocation(TargetLocation);
		}
	}
};