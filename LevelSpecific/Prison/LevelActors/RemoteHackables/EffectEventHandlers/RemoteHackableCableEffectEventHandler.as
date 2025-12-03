struct FRemoteHackableCableSocketEventData
{
	UPROPERTY()
	ARemoteHackableCableSocket Socket;
}

UCLASS(Abstract)
class URemoteHackableCableEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartHacking() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopHacking() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitStartPoint() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ConnectedToSocket(FRemoteHackableCableSocketEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DisconnectedFromSocket(FRemoteHackableCableSocketEventData Data) {}
}