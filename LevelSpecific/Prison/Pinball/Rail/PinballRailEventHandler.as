struct FPinballRailOnBallEnterEventData
{
	UPROPERTY(BlueprintReadOnly)
	UPinballBallComponent BallComp;

	UPROPERTY(BlueprintReadOnly)
	EPinballRailHeadOrTail Side;
};

struct FPinballRailOnBallExitEventData
{
	UPROPERTY(BlueprintReadOnly)
	UPinballBallComponent BallComp;

	UPROPERTY(BlueprintReadOnly)
	EPinballRailHeadOrTail Side;
};

struct FPinballRailOnLaunchedEventData
{
	UPROPERTY(BlueprintReadOnly)
	EPinballRailHeadOrTail Side;

	UPROPERTY(BlueprintReadOnly)
	EPinballRailEnterOrExit EnterOrExit;
};

struct FPinballRailSyncPointEventData
{
	UPROPERTY(BlueprintReadOnly)
	UPinballBallComponent BallComp;
	
	UPROPERTY(BlueprintReadOnly)
	UPinballRailSyncPoint SyncPoint;

	UPROPERTY(BlueprintReadOnly)
	EPinballRailHeadOrTail HeadOrTail;
};

struct FPinballRailPredictionReceivedLaunchTimeSyncPointEventData
{
	UPROPERTY(BlueprintReadOnly)
	UPinballRailSyncPoint SyncPoint;

	UPROPERTY(BlueprintReadOnly)
	float TimeUntilLaunch;
};

struct FPinballRailPredictionCancelledSyncPointEventData
{
	UPROPERTY(BlueprintReadOnly)
	UPinballRailSyncPoint SyncPoint;
};

UCLASS(Abstract)
class UPinballRailEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	APinballRail Rail;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rail = Cast<APinballRail>(Owner);
	}

	/**
	 * Enter / Exit
	 */

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallEnter(FPinballRailOnBallEnterEventData EventData) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallExit(FPinballRailOnBallExitEventData EventData) {}

	/**
	 * Launch
	 */

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchBall(FPinballRailOnLaunchedEventData EventData) {}

	/**
	 * Sync Points
	 */

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallEnteredSyncPoint(FPinballRailSyncPointEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallExitedSyncPoint(FPinballRailSyncPointEventData EventData) {}

	/**
	 * Prediction
	 */

	UFUNCTION(BlueprintEvent, Meta = ())
	void OnPredictionEnteredSyncPoint(FPinballRailSyncPointEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = ())
	void OnPredictionReceivedLaunchTimeSyncPoint(FPinballRailPredictionReceivedLaunchTimeSyncPointEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = ())
	void OnPredictionCancelledSyncPoint(FPinballRailPredictionCancelledSyncPointEventData EventData) {}
};