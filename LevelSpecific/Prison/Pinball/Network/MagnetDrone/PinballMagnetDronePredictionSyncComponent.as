struct FPinballPredictionSyncedData
{
	FPinballPredictionSyncedMovementData MovementData;
	FPinballPredictionSyncedLaunchedData LaunchedData;
	FPinballPredictionSyncedRailData RailData;
	FPinballPredictionSyncedAttractionData AttractionData;
	FPinballPredictionSyncedAttachedData AttachedData;

#if !RELEASE
	void LogToTemporalLog(FTemporalLog& TemporalLog, bool bHasControl, float CrumbTime) const
	{
		TemporalLog
			.Value("01#SyncedData;HasControl", bHasControl)
			.Value("01#SyncedData;CrumbTime", CrumbTime)

			.Struct("01#MovementData;MovementData", MovementData)
			.Struct("02#LaunchedData;LaunchedData", LaunchedData)
			.Struct("03#RailData;RailData", RailData)
		;
	}
#endif
};

struct FPinballPredictionSyncedMovementData
{
	FHitResult GroundContact;
	bool bIsJumping = false;
	bool bIsDashing = false;

	FPinballPredictionSyncedMovementData(const AHazePlayerCharacter Player)
	{
		auto MoveComp = UPlayerMovementComponent::Get(Player);
		GroundContact = MoveComp.GroundContact.ConvertToHitResult();

		auto JumpComp = UMagnetDroneJumpComponent::Get(Player);
		bIsJumping = JumpComp.IsJumping();

		auto DroneComp = UMagnetDroneComponent::Get(Player);
		bIsDashing = DroneComp.IsDashing();
	}
}

struct FPinballPredictionSyncedLaunchedData
{
	bool bWasLaunched = false;

	FPinballPredictionSyncedLaunchedData(const UPinballMagnetDroneLaunchedComponent LaunchedComp)
	{
		bWasLaunched = LaunchedComp.WasLaunched();
	}
};

struct FPinballPredictionSyncedRailData
{
	APinballRail Rail = nullptr;
	bool bIsInRail = false;
    float32 Speed = 0.0;
	float32 DistanceAlongSpline = 0.0;

	EPinballRailHeadOrTail EnterSide = EPinballRailHeadOrTail::None;
    EPinballRailHeadOrTail ExitSide = EPinballRailHeadOrTail::None;

	UPinballRailSyncPoint EnterSyncPoint = nullptr;
	EPinballBallRailSyncPointState EnterSyncPointState = EPinballBallRailSyncPointState::NoSyncPoint;
	float PredictedEnterSyncPointLaunchTime = -1;

	UPinballRailSyncPoint ExitSyncPoint = nullptr;
	EPinballBallRailSyncPointState ExitSyncPointState = EPinballBallRailSyncPointState::NoSyncPoint;
	float PredictedExitSyncPointLaunchTime = -1;

	FPinballPredictionSyncedRailData(const UPinballMagnetDroneRailComponent RailComp)
	{
		Rail = RailComp.Rail;
		bIsInRail = RailComp.bIsInRail;
		Speed = float32(RailComp.Speed);
		DistanceAlongSpline = float32(RailComp.DistanceAlongSpline);

		EnterSide = RailComp.EnterSide;
		ExitSide = RailComp.ExitSide;

		EnterSyncPoint = RailComp.EnterSyncPoint;
		EnterSyncPointState = RailComp.EnterSyncPointState;
		PredictedEnterSyncPointLaunchTime = RailComp.PredictedEnterSyncPointLaunchTime;

		ExitSyncPoint = RailComp.ExitSyncPoint;
		ExitSyncPointState = RailComp.ExitSyncPointState;
		PredictedExitSyncPointLaunchTime = RailComp.PredictedExitSyncPointLaunchTime;
	}

	bool IsEnterSyncPointLaunching(float CrumbTime) const
	{
		if(PredictedEnterSyncPointLaunchTime < 0)
			return false;

		if(PredictedEnterSyncPointLaunchTime > CrumbTime)
			return false;

		return true;
	}

	bool IsExitSyncPointLaunching(float CrumbTime) const
	{
		if(PredictedExitSyncPointLaunchTime < 0)
			return false;

		if(PredictedExitSyncPointLaunchTime > CrumbTime)
			return false;

		return true;
	}
};

struct FPinballPredictionSyncedAttractionData
{
	FMagnetDroneTargetData AttractionTarget;
	EMagnetDroneStartAttractionInstigator AttractionTargetInstigator;
	float AttractionAlpha = 0;
	float StartAttractTime = 0;

	FPinballPredictionSyncedAttractionData(const AHazePlayerCharacter BallPlayer)
	{
		auto AttractionComp = UMagnetDroneAttractionComponent::Get(BallPlayer);
		if(AttractionComp.HasAttractionTarget())
			AttractionTarget = AttractionComp.GetAttractionTarget();
		else
			AttractionTarget = FMagnetDroneTargetData();

		AttractionTargetInstigator = AttractionComp.GetAttractionTargetInstigator();
		AttractionAlpha = AttractionComp.GetAttractionAlpha();
		StartAttractTime = AttractionComp.GetStartAttractTime();
	}
};

struct FPinballPredictionSyncedAttachedData
{
	FMagnetDroneAttachedData AttachedData;

	FPinballPredictionSyncedAttachedData(const AHazePlayerCharacter BallPlayer)
	{
		auto AttachedComp = UMagnetDroneAttachedComponent::Get(BallPlayer);
		AttachedData = AttachedComp.AttachedData;
	}
};

/**
 * Additional data that needs to be synced for the prediction
 */
UCLASS(NotBlueprintable)
class UPinballPredictionSyncComponent : UHazeCrumbSyncedStructComponent
{
	default SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default SleepAfterIdleTime = MAX_flt;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballMagnetDronePredictionSync");
#endif
	}

	void InterpolateValues(FPinballPredictionSyncedData& OutValue, FPinballPredictionSyncedData A, FPinballPredictionSyncedData B, float Alpha) const
	{
		// We could interpolate values, but we don't because we always want the latest value when we get this struct
		OutValue = B;
	}
};