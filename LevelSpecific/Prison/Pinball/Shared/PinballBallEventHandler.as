struct FPinballOnLaunchedEventData
{
	UPROPERTY()
	FVector LaunchLocation;

	UPROPERTY()
	FVector LaunchVelocity;

	UPROPERTY()
	UPinballLauncherComponent WasLaunchedBy;

	UPROPERTY()
	bool bIsProxy;

	FPinballOnLaunchedEventData(FPinballBallLaunchData LaunchData)
	{
		check(LaunchData.IsValid());
		LaunchLocation = LaunchData.LaunchLocation;
		LaunchVelocity = LaunchData.LaunchVelocity;
		WasLaunchedBy = LaunchData.LaunchedBy;
		bIsProxy = LaunchData.bIsProxy;
	}
};

UCLASS(Abstract)
class UPinballBallEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	UPinballBallComponent BallComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallComp = UPinballBallComponent::Get(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunched(FPinballOnLaunchedEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopLaunch() {}

	UFUNCTION(BlueprintPure)
	USceneComponent GetAttachComponent() const
	{
		UHazeOffsetComponent OffsetComp = UHazeOffsetComponent::Get(BallComp.Owner);
		if(OffsetComp != nullptr)
			return OffsetComp;
		
		return BallComp.Owner.RootComponent;
	}
};