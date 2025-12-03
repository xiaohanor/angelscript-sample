struct FPinballBallRailOnEnterRailEventData
{
	UPROPERTY(BlueprintReadOnly)
	APinballRail Rail;

	UPROPERTY(BlueprintReadOnly)
	EPinballRailHeadOrTail Side;
};

struct FPinballBallRailOnExitRailEventData
{
	UPROPERTY(BlueprintReadOnly)
	APinballRail Rail;

	UPROPERTY(BlueprintReadOnly)
	EPinballRailHeadOrTail Side;
};

struct FPinballBallRailOnLaunchedEventData
{
	UPROPERTY(BlueprintReadOnly)
	APinballRail Rail;

	UPROPERTY(BlueprintReadOnly)
	EPinballRailHeadOrTail Side;

	UPROPERTY(BlueprintReadOnly)
	EPinballRailEnterOrExit EnterOrExit;
};

struct FPinballBallRailSyncPointEventData
{
	UPROPERTY(BlueprintReadOnly)
	APinballRail Rail;
	
	UPROPERTY(BlueprintReadOnly)
	UPinballRailSyncPoint SyncPoint;

	UPROPERTY(BlueprintReadOnly)
	EPinballRailHeadOrTail HeadOrTail;
};

struct FPinballBallRailPredictionCancelledSyncPointEventData
{
	UPROPERTY(BlueprintReadOnly)
	APinballRail Rail;
	
	UPROPERTY(BlueprintReadOnly)
	UPinballRailSyncPoint SyncPoint;
};

UCLASS(Abstract)
class UPinballBallRailEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	UPinballBallComponent BallComp;

	UPROPERTY(BlueprintReadOnly)
	UPinballBallRailComponent RailComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallComp = UPinballBallComponent::Get(Owner);
		RailComp = UPinballBallRailComponent::Get(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnterRail(FPinballBallRailOnEnterRailEventData EventData) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExitRail(FPinballBallRailOnExitRailEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchedByRail(FPinballBallRailOnLaunchedEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnterSyncPoint(FPinballBallRailSyncPointEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExitSyncPoint(FPinballBallRailSyncPointEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPredictionCancelledSyncPoint(FPinballBallRailPredictionCancelledSyncPointEventData EventData) {}

	UFUNCTION(BlueprintPure)
	USceneComponent GetAttachComponent() const
	{
		UHazeOffsetComponent OffsetComp = UHazeOffsetComponent::Get(BallComp.Owner);
		if(OffsetComp != nullptr)
			return OffsetComp;
		
		return BallComp.Owner.RootComponent;
	}
};