struct FDentistBossCupMoveOverPlayerActivationParams
{
	bool bIsLeftGrabber;
	float MoveDuration;
	EDentistBossTool CupType;
}

class UDentistBossCupMoveOverPlayerCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossToolCup Cup;

	UDentistBossTargetComponent TargetComp;

	FDentistBossCupMoveOverPlayerActivationParams Params;

	UDentistBossSettings Settings;

	AHazePlayerCharacter TargetPlayer;
	FVector ActivateLocation;
	FRotator ActivateRotation;

	const float TargetZOffset = 1000.0;
	const float DurationFractionUntilFoundPlayer = 0.85;

	float DurationUntilFoundPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossCupMoveOverPlayerActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DentistBossDevToggles::InfiniteCupTelegraph.IsEnabled())
			return false;

		if(ActiveDuration > Params.MoveDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetPlayer = TargetComp.Target.Get();

		FTransform BoneTransform = Dentist.GetIKTransform(EDentistBossArm::LeftTop);
		ActivateLocation = BoneTransform.Location;
		ActivateRotation = BoneTransform.Rotator();

		DurationUntilFoundPlayer = Params.MoveDuration * DurationFractionUntilFoundPlayer;
		Dentist.bCupCaptureTelegraphDone = false;
		Dentist.CurrentSortType = EDentistBossToolCupSortType::None;
		Dentist.CupSortAnimSpeed = 1.0;
		Dentist.bCupChosen = false;
		Dentist.CupManager.bCupSortingFinished = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetLocation = TargetPlayer.ActorLocation;
		TargetLocation.Z = TargetPlayer.ActorLocation.Z + TargetZOffset;
		auto TempLog = TEMPORAL_LOG(Dentist, "Cup").Section("Move over Player")
			.Sphere("Start Location", ActivateLocation, 50, FLinearColor::LucBlue, 10)
			.Sphere("Target Location", TargetLocation, 50, FLinearColor::Red, 10)
			.Value("Active Duration", ActiveDuration)
		;

		FRotator TargetRotation = FRotator::MakeFromXZ(-FVector::UpVector, Dentist.ActorRightVector);
		FVector BoneLocation;
		FRotator BoneRotation;
		if(ActiveDuration < DurationUntilFoundPlayer)
		{
			float MoveAlpha = ActiveDuration / DurationUntilFoundPlayer;
			MoveAlpha = Math::EaseInOut(0.0, 1.0, MoveAlpha, 3);

			TempLog.Value("Move Alpha", MoveAlpha);

			BoneLocation = Math::Lerp(ActivateLocation, TargetLocation, MoveAlpha);
			BoneRotation = Math::LerpShortestPath(ActivateRotation, TargetRotation, MoveAlpha);
		}
		else
		{
			BoneLocation = TargetLocation;
			BoneRotation = TargetRotation;
		}

		Dentist.SetIKTransform(EDentistBossArm::LeftTop, BoneLocation, BoneRotation);
	}
};