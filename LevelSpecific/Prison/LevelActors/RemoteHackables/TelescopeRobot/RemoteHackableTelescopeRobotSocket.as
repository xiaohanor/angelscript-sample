event void FRemoteHackableTelescopeRobotSocketEvent();

UCLASS(Abstract)
class ARemoteHackableTelescopeRobotSocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SocketBase;

	UPROPERTY(DefaultComponent, Attach = SocketBase)
	USceneComponent SocketRoot;

	UPROPERTY(DefaultComponent, Attach = SocketRoot)
	UCapsuleComponent SocketTrigger;

	UPROPERTY()
	FRemoteHackableTelescopeRobotSocketEvent OnSocketActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SocketTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterSocket");
	}

	UFUNCTION()
	private void EnterSocket(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		ARemoteHackableTelescopeRobot Robot = Cast<ARemoteHackableTelescopeRobot>(OtherActor);
		if (Robot == nullptr)
			return;

		Robot.ActivateDelayedDestroy();
		OnSocketActivated.Broadcast();
	}
}