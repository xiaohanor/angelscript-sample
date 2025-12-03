class URemoteHackingEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintEvent, meta = (AutoCreateBPNode))
	void OnLaunchStarted(FRemoteHackingStartParams HackingParams) {};

	UFUNCTION(BlueprintEvent, meta = (AutoCreateBPNode))
	void OnLaunchTick(FRemoteHackingLaunchTickParams Params) {}

	UFUNCTION(BlueprintEvent, meta = (AutoCreateBPNode))
	void OnLaunchComplete() {};

	UFUNCTION(BlueprintEvent, meta = (AutoCreateBPNode))
	void OnHackingStarted() {};

	UFUNCTION(BlueprintEvent, meta = (AutoCreateBPNode))
	void OnHackingStopped() {};

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetPlayerOwner() const
	{
		return PlayerOwner;
	}
}