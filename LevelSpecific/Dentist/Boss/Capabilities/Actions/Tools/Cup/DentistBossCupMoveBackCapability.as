struct FDentistBossCupMoveBackActivationParams
{
	float MoveDuration;
	EDentistBossTool CupType;
}

class UDentistBossCupMoveBackCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossToolCup CaptureCup;
	FDentistBossCupMoveBackActivationParams Params;

	UDentistBossSettings Settings;

	FVector StartLocation;
	FRotator StartRotation;

	bool bLeftCupIsAttached = false;
	bool bMiddleCupIsAttached = false;
	bool bRightCupIsAttached = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossCupMoveBackActivationParams InParams)
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
		if(ActiveDuration > Params.MoveDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CaptureCup = Cast<ADentistBossToolCup>(Dentist.Tools[Params.CupType]);

		FTransform HandTransform = Dentist.GetIKTransform(EDentistBossArm::LeftTop);
		StartLocation = HandTransform.Location;
		StartRotation = HandTransform.Rotator();
		Dentist.bCupCaptureTelegraphDone = true;

		bLeftCupIsAttached = true;
		bMiddleCupIsAttached = true;
		bRightCupIsAttached = true; 
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(bLeftCupIsAttached)
			DetachCup(EDentistBossTool::CupLeft);
		if(bMiddleCupIsAttached)
			DetachCup(EDentistBossTool::CupMiddle);
		if(bRightCupIsAttached)
			DetachCup(EDentistBossTool::CupRight);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CheckIfCupsShouldBeDetached();
		auto MoveBackSection = TEMPORAL_LOG(Dentist, "Cup").Section("Move Back");

		if(bLeftCupIsAttached)
		{
			float MoveAlpha = ActiveDuration / DentistBossTimings::CupMoveBackDuration;
			MoveAlpha = Math::Saturate(MoveAlpha);
			MoveAlpha = Math::EaseInOut(0.0, 1.0, MoveAlpha, 2.0);
			
			FVector TargetLocation = CaptureCup.GetTargetLocation();
			FVector NewLocation = Math::Lerp(StartLocation, TargetLocation, MoveAlpha);
			NewLocation.Z = Dentist.Cake.ActorLocation.Z + DentistBossMeasurements::CupHeight;
			FRotator TargetRotation = FRotator::MakeFromXZ(-FVector::UpVector, Dentist.ActorRightVector);
			Dentist.SetIKTransform(EDentistBossArm::LeftTop, NewLocation, TargetRotation);

			MoveBackSection
				.Sphere("Start Location", StartLocation, 50, FLinearColor::LucBlue, 10)
				.Sphere("Target Location", TargetLocation, 50, FLinearColor::Red, 10)
				.Value("Active Duration", ActiveDuration)
				.Value("Move Alpha", MoveAlpha)
			;
		}
		else
		{
			Dentist.LeftUpperHandTargetingTransform = FTransform::Identity;
		}

		MoveBackSection
			.Value("Left Cup Is attached", bLeftCupIsAttached)
			.Value("Middle Cup Is attached", bMiddleCupIsAttached)
			.Value("Right Cup Is attached", bRightCupIsAttached)
		;
	}

	void CheckIfCupsShouldBeDetached()
	{
		if(bLeftCupIsAttached
		&& ActiveDuration > DentistBossTimings::CupCatchLeftCupDetachDelay)
			DetachCup(EDentistBossTool::CupLeft);
		if(bMiddleCupIsAttached
		&& ActiveDuration > DentistBossTimings::CupCatchMiddleCupDetachDelay)
			DetachCup(EDentistBossTool::CupMiddle);
		if(bRightCupIsAttached
		&& ActiveDuration > DentistBossTimings::CupCatchRightCupDetachDelay)
			DetachCup(EDentistBossTool::CupRight);
	}

	void DetachCup(EDentistBossTool CupType)
	{
		ADentistBossToolCup DetachmentCup;
		if(CupType == EDentistBossTool::CupLeft)
		{
			DetachmentCup = Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupLeft]);
			bLeftCupIsAttached = false;
		}
		else if(CupType == EDentistBossTool::CupMiddle)
		{
			DetachmentCup = Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupMiddle]);
			bMiddleCupIsAttached = false;
		}
		else
		{
			DetachmentCup = Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupRight]);
			bRightCupIsAttached = false;
		}
		DetachmentCup.DetachFromActor(EDetachmentRule::KeepWorld);
		DetachmentCup.PutCupAtTarget();
		
		CupPlacedEvent(CupType);
	}

	void CupPlacedEvent(EDentistBossTool CupEnum)
	{
		FDentistBossEffectHandlerOnCupPlacedOnCakeParams EventParams;
		EventParams.Cup = Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupRight]);
		EventParams.bPlayerIsInCup = EventParams.Cup.RestrainedPlayer.IsSet();
		UDentistBossEffectHandler::Trigger_OnCupPlacedOnCake(Dentist, EventParams);
	}
};