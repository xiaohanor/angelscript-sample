enum EPinballBallRailSyncPointState
{
	NoSyncPoint,
	Waiting,
	FinishedWaiting
};

UCLASS(NotBlueprintable, NotPlaceable)
class UPinballMagnetDroneRailComponent : UPinballBallRailComponent
{
	access Internal = private, UPinballMagnetDroneRailComponent, FPinballPredictionSyncedRailData;

	/**
	 * Control State
	 */
    APinballRail Rail = nullptr;
	access:Internal bool bIsInRail = false;
    float Speed = 0.0;
	float DistanceAlongSpline = 0.0;

    EPinballRailHeadOrTail EnterSide = EPinballRailHeadOrTail::None;
    EPinballRailHeadOrTail ExitSide = EPinballRailHeadOrTail::None;

	UPinballRailSyncPoint EnterSyncPoint = nullptr;
	EPinballBallRailSyncPointState EnterSyncPointState = EPinballBallRailSyncPointState::NoSyncPoint;
	float PredictedEnterSyncPointLaunchTime = -1;

	UPinballRailSyncPoint ExitSyncPoint = nullptr;
	EPinballBallRailSyncPointState ExitSyncPointState = EPinballBallRailSyncPointState::NoSyncPoint;
	float PredictedExitSyncPointLaunchTime = -1;

	private AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		auto RespawnComp = UPlayerRespawnComponent::Get(Player);
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnRespawn");

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballMagnetDroneRail");
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		TemporalLog.Value(f"Is In Rail", bIsInRail);

		if(bIsInRail)
		{
			TemporalLog.Value(f"Rail", Rail.Name);
			TemporalLog.Value(f"Speed", Speed);
			TemporalLog.Value(f"Enter Side", EnterSide);
			TemporalLog.Value(f"Distance Along Spline", DistanceAlongSpline);
		}
#endif
	}

	void EnterRail(APinballRail InRail, EPinballRailHeadOrTail InEnterSide) override
	{
		check(HasControl());

		if(IsInAnyRail())
			return;

		Rail = InRail;
		bIsInRail = true;
		EnterSide = InEnterSide;

		if(InRail.ShouldSyncWhenEntering(InEnterSide))
		{
			EnterSyncPoint = InRail.GetSyncPoint(InEnterSide);
			EnterSyncPointState = EPinballBallRailSyncPointState::Waiting;
		}

		ExitSyncPointState = EPinballBallRailSyncPointState::NoSyncPoint;

#if !RELEASE
		TEMPORAL_LOG(this).Event(f"Entered Rail {InRail}. EnterSide: {InEnterSide:n}");
#endif
	}

    void ExitRail(const APinballRail InRail, EPinballRailHeadOrTail InExitSide, FInstigator Instigator)
    {
        if(!ensure(IsInRail(Rail)))
            return;

		if(Rail.ShouldSyncWhenExiting(InExitSide))
		{
			ExitSyncPoint = Rail.GetSyncPoint(InExitSide);
			ExitSyncPointState = EPinballBallRailSyncPointState::Waiting;
		}
		else
		{
			check(Rail == InRail);
			check(bIsInRail);
			bIsInRail = false;
			ExitSide = InExitSide;

#if !RELEASE
			TEMPORAL_LOG(this).Event(f"Exited Rail {InRail}. ExitSide: {InExitSide:n}, Instigator: {Instigator}");
#endif
		}
    }

    bool IsInAnyRail() const
    {
		if(!bIsInRail)
			return false;

		if(!IsValid(Rail))
			return false;

		if(Rail.IsActorDisabled())
			return false;

        return true;
    }

	bool IsInRail(const APinballRail InRail) const
	{
		if(!IsInAnyRail())
			return false;

		return Rail == InRail;
	}

	bool IsWaitingSyncPoint() const
	{
		return EnterSyncPointState == EPinballBallRailSyncPointState::Waiting || ExitSyncPointState == EPinballBallRailSyncPointState::Waiting;
	}

	void Reset(bool bIsExit)
	{
		// The rail is not nulled on purpose, because that can cause null refs. Always check bIsInRail instead!
		bIsInRail = false;
		Speed = 0;
		DistanceAlongSpline = 0;

		EnterSide = EPinballRailHeadOrTail::None;

		EnterSyncPoint = nullptr;
		EnterSyncPointState = EPinballBallRailSyncPointState::NoSyncPoint;
		PredictedEnterSyncPointLaunchTime = -1;

		ExitSyncPoint = nullptr;
		ExitSyncPointState = EPinballBallRailSyncPointState::FinishedWaiting;
		PredictedExitSyncPointLaunchTime = -1;

		// Some state should not be reset on exiting, only when fully resetting
		if(bIsExit)
			return;

		ExitSide = EPinballRailHeadOrTail::None;
	}

	UFUNCTION()
	private void OnRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		Reset(false);
	}
};