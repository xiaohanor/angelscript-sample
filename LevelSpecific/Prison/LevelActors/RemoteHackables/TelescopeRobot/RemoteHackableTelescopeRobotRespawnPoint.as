UCLASS(Abstract)
class ARemoteHackableTelescopeRobotRespawnPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ElevatorRoot;

	ARemoteHackableTelescopeRobot AttachedRobot;

	void RespawnRobot(ARemoteHackableTelescopeRobot Robot)
	{
		AttachedRobot = Robot;
		BP_RespawnRobot();
	}

	UFUNCTION(BlueprintEvent)
	void BP_RespawnRobot() {}

	UFUNCTION()
	void FinishRespawning()
	{
		AttachedRobot.FinishRespawning();
	}
}