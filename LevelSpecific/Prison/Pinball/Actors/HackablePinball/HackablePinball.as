UCLASS(Abstract)
class AHackablePinball : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent HackTerminal;

	UPROPERTY(DefaultComponent, Attach = HackTerminal)
	USwarmDroneHijackTargetableComponent HijackableTarget;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor CameraActor;

	bool bIsHacked = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Pinball::GetPaddlePlayer());
	}
}