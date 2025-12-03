struct FPinballBossBallSyncedData
{
	FPinballBossBallSyncedMovementData MovementData;
	FPinballBossBallSyncedLaunchedData LaunchedData;

#if !RELEASE
	void LogToTemporalLog(FTemporalLog& TemporalLog, bool bHasControl, float CrumbTime) const
	{
		TemporalLog
			.Value("01#SyncedData;HasControl", bHasControl)
			.Value("01#SyncedData;CrumbTime", CrumbTime)

			.Struct("01#MovementData;MovementData", MovementData)
			.Struct("02#LaunchedData;LaunchedData", LaunchedData)
		;
	}
#endif
};

struct FPinballBossBallSyncedMovementData
{
	FHitResult GroundContact;

	FPinballBossBallSyncedMovementData(const APinballBossBall BossBall)
	{
		auto MoveComp = UHazeMovementComponent::Get(BossBall);
		GroundContact = MoveComp.GroundContact.ConvertToHitResult();
	}
}

struct FPinballBossBallSyncedLaunchedData
{
	bool bWasLaunched = false;

	FPinballBossBallSyncedLaunchedData(const UPinballBossBallLaunchedComponent LaunchedComp)
	{
		bWasLaunched = LaunchedComp.WasLaunched();
	}
};

UCLASS(NotBlueprintable)
class UPinballBossBallSyncComponent : UHazeCrumbSyncedStructComponent
{
	default SyncRate = EHazeCrumbSyncRate::High;
	default SleepAfterIdleTime = MAX_flt;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballBossBallSync");
#endif
	}

	void InterpolateValues(FPinballBossBallSyncedData& OutValue, FPinballBossBallSyncedData A, FPinballBossBallSyncedData B, float Alpha) const
	{
		// We could interpolate values, but we don't because we always want the latest value when we get this struct
		OutValue = B;
	}
};