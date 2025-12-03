struct FTundraPlayerSnowMonkeyIceKingBossPunchAnimData
{
	bool bPunchingThisFrame = false;
	bool bDoBackFlip = false;
	bool bShouldPlayLastFinalPunch = false;
}

enum ETundraPlayerSnowMonkeyIceKingBossPunchType
{
	FirstPunch,
	SecondPunch,
	FinalPunch
}

event void FTundraPlayerSnowMonkeyIceKingBossPunchPunchEvent();
event void FTundraPlayerSnowMonkeyIceKingBossPunchEvent(ETundraPlayerSnowMonkeyIceKingBossPunchType PunchType);

class UTundraPlayerSnowMonkeyIceKingBossPunchComponent : UActorComponent
{
	access ReadOnly = private, * (readonly);

	access:ReadOnly UTundraSnowMonkeyIceKingBossPunchTargetableComponent CurrentBossPunchTargetable;
	access:ReadOnly ATundraSnowMonkeyIceKingBossPunchInteractionActor CurrentBossPunchInteractionActor;
	int AmountOfPunchesPerformed = 0;
	float TimeOfEnterBossPunch = -100.0;
	float TimeOfLastPunch = -100.0;
	float RealTimeOfLastPunch = -100.0;
	bool bWithinPrePunchWindow = false;
	bool bWithinRootMotionState = false;
	bool bWithinSlowMotionWindow = false;
	float SlowMotionWindowLength;

	UPROPERTY()
	FTundraPlayerSnowMonkeyIceKingBossPunchPunchEvent OnDealDamagePunch;
	
	UPROPERTY()
	FTundraPlayerSnowMonkeyIceKingBossPunchPunchEvent OnPunch;

	UPROPERTY()
	FTundraPlayerSnowMonkeyIceKingBossPunchEvent OnBackFlipStarted;

	UPROPERTY()
	FTundraPlayerSnowMonkeyIceKingBossPunchEvent OnStartEnter;

	UPROPERTY()
	FTundraPlayerSnowMonkeyIceKingBossPunchEvent OnEntered;

	FTundraPlayerSnowMonkeyIceKingBossPunchAnimData AnimData;

	AHazePlayerCharacter Player;
	ATundraSnowMonkeyIceKingBossPunchInteractionActor ForcedBossPunchActor;
	UTundraPlayerSnowMonkeyIceKingBossPunchSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Settings = UTundraPlayerSnowMonkeyIceKingBossPunchSettings::GetSettings(Player);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this)
			.Value("bWithinPrePunchWindow", bWithinPrePunchWindow)
			.Value("bWithinRootMotionState", bWithinRootMotionState)
			.Value("bWithinSlowMotionWindow", bWithinSlowMotionWindow)
		;
	}
#endif

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	void CrumbEnterSlowMotionWindow(float WindowLength)
	{
		bWithinSlowMotionWindow = true;
		SlowMotionWindowLength = WindowLength;
	}

	bool CanPunch() const
	{
		if(CurrentBossPunchTargetable == nullptr)
			return false;

		if(AmountOfPunchesPerformed >= TypeSettings.BossPunchesAmount)
			return false;

		if(bWithinPrePunchWindow)
			return false;

		if(bWithinRootMotionState)
			return false;

		if(Time::GetGameTimeSince(TimeOfLastPunch) < TypeSettings.MinimumPunchCooldown)
			return false;

		if(AmountOfPunchesPerformed == 0 && Time::GetGameTimeSince(TimeOfEnterBossPunch) < TypeSettings.DelayBeforeFirstPunch)
			return false;

		return true;
	}

	void EnterBossPunch(UTundraSnowMonkeyIceKingBossPunchTargetableComponent Targetable)
	{
		CurrentBossPunchTargetable = Targetable;
		CurrentBossPunchTargetable.Disable(this);
		CurrentBossPunchInteractionActor = Cast<ATundraSnowMonkeyIceKingBossPunchInteractionActor>(CurrentBossPunchTargetable.Owner);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Death, this);
		TimeOfEnterBossPunch = Time::GetGameTimeSeconds();
	}

	void ExitBossPunch()
	{
		if(CurrentBossPunchTargetable == nullptr)
			return;

		AmountOfPunchesPerformed = 0;
		CurrentBossPunchTargetable.Enable(this);
		CurrentBossPunchTargetable = nullptr;
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Death, this);
	}

	FTundraPlayerSnowMonkeyIceKingBossPunchTypeSettings GetTypeSettings() const property
	{
		devCheck(CurrentBossPunchInteractionActor != nullptr, "Tried to get type settings when boss punch interaction actor is null!");
		switch(CurrentBossPunchInteractionActor.Type)
		{
			case ETundraPlayerSnowMonkeyIceKingBossPunchType::FirstPunch:
				return Settings.FirstTypeSettings;
			case ETundraPlayerSnowMonkeyIceKingBossPunchType::SecondPunch:
				return Settings.SecondTypeSettings;
			case ETundraPlayerSnowMonkeyIceKingBossPunchType::FinalPunch:
				return Settings.FinalTypeSettings;
		}
	}
	
	FName GetAnimationFeatureTag() const property
	{
		devCheck(CurrentBossPunchInteractionActor != nullptr, "Tried to get feature tag when boss punch interaction actor is null!");
		switch(CurrentBossPunchInteractionActor.Type)
		{
			case ETundraPlayerSnowMonkeyIceKingBossPunchType::FirstPunch:
				return n"SnowMonkeyBossPunch";
			case ETundraPlayerSnowMonkeyIceKingBossPunchType::SecondPunch:
				return n"SnowMonkeyBossSecondPunch";
			case ETundraPlayerSnowMonkeyIceKingBossPunchType::FinalPunch:
				return n"SnowMonkeyBossFinalPunch";
		}
	}

	ETundraPlayerSnowMonkeyIceKingBossPunchType GetType() const property
	{
		devCheck(CurrentBossPunchInteractionActor != nullptr, "Tried to get punch type when boss punch interaction actor is null!");
		return CurrentBossPunchInteractionActor.Type;
	}
}