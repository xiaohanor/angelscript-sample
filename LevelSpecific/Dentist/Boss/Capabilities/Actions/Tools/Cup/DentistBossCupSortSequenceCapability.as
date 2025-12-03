struct FDentistBossCupSortSequenceActivationParams
{
	EDentistBossToolCupSortType SortType;
	float Duration;
}

class UDentistBossCupCupSortSequenceCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	ADentistBoss Dentist;
	ADentistBossCupManager CupManager;

	USceneComponent RotatorRoot;
	
	FDentistBossCupSortSequenceActivationParams Params;

	UDentistBossSettings Settings;
	UDentistBossTargetComponent TargetComp;

	FRotator StartRotation;
	FHazeAcceleratedRotator AccCupRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		CupManager = Dentist.CupManager;

		Settings = UDentistBossSettings::GetSettings(Dentist);
		TargetComp = UDentistBossTargetComponent::Get(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossCupSortSequenceActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Params.Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Dentist.CurrentSortType = Params.SortType;
		Dentist.CupSortAnimSpeed = 1.1 / Params.Duration;

		UDentistBossEffectHandler::Trigger_OnCupSwitchedPlaceStart(Dentist, GetCupSwitchPlaceEventParams());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ADentistBossToolCup LeftmostCup = Cast<ADentistBossToolCup>(Dentist.Tools[GetLeftmostCup()]);
		LeftmostCup.PutCupAtTarget();
		ADentistBossToolCup RightmostCup = Cast<ADentistBossToolCup>(Dentist.Tools[GetRightmostCup()]);
		RightmostCup.PutCupAtTarget();
		UDentistBossEffectHandler::Trigger_OnCupSwitchedPlaceStop(Dentist, GetCupSwitchPlaceEventParams());
		Dentist.CurrentSortType = EDentistBossToolCupSortType::None;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// If the player that we haven't captured is overlapping with a cup that we're moving, kill them!
		CheckCollisionWithCup(Dentist.Tools[EDentistBossTool::CupLeft]);
		CheckCollisionWithCup(Dentist.Tools[EDentistBossTool::CupMiddle]);
		CheckCollisionWithCup(Dentist.Tools[EDentistBossTool::CupRight]);
	}

	void CheckCollisionWithCup(ADentistBossTool CupTool)
	{
		if (TargetComp.CupRestrainedPlayer == nullptr)
			return;
		ADentistBossToolCup Cup = Cast<ADentistBossToolCup>(CupTool);
		if (Cup == nullptr)
			return;
		AHazePlayerCharacter OtherPlayer = TargetComp.CupRestrainedPlayer.OtherPlayer;
		if (OtherPlayer != nullptr && OtherPlayer.CapsuleComponent.TraceOverlappingComponent(Cup.MeshComp))
			OtherPlayer.KillPlayer();
	}

	EDentistBossTool GetLeftmostCup()
	{
		if(Params.SortType == EDentistBossToolCupSortType::Left)
			return EDentistBossTool::CupLeft;
		if(Params.SortType == EDentistBossToolCupSortType::Sides)
			return EDentistBossTool::CupLeft;
		else
			return EDentistBossTool::CupMiddle;
	}

	EDentistBossTool GetRightmostCup()
	{
		if(Params.SortType == EDentistBossToolCupSortType::Left)
			return EDentistBossTool::CupMiddle;
		if(Params.SortType == EDentistBossToolCupSortType::Sides)
			return EDentistBossTool::CupRight;
		else
			return EDentistBossTool::CupRight;
	}

	FRotator GetTargetRotation() const
	{
		return StartRotation + FRotator(0, 180, 0);
	}

	FDentistBossEffectHandlerOnCupSwitchPlaceParams GetCupSwitchPlaceEventParams()
	{
		FDentistBossEffectHandlerOnCupSwitchPlaceParams EventParams;
		ADentistBossToolCup LeftmostCup = Cast<ADentistBossToolCup>(Dentist.Tools[GetLeftmostCup()]);
		ADentistBossToolCup RightmostCup = Cast<ADentistBossToolCup>(Dentist.Tools[GetRightmostCup()]);
		EventParams.LeftmostCup = LeftmostCup;
		EventParams.bPlayerIsInLeftmostCup = LeftmostCup.RestrainedPlayer.IsSet();
		EventParams.RightmostCup = RightmostCup;
		EventParams.bPlayerIsInRightmostCup = RightmostCup.RestrainedPlayer.IsSet();
		EventParams.SortType = Params.SortType;
		return EventParams;
	}
};