UCLASS(Abstract)
class URemoteHackableSmokeRobotEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	ARemoteHackableSmokeRobot SmokeRobot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SmokeRobot = Cast<ARemoteHackableSmokeRobot>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartHacked()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopHacked()
	{
	}
};