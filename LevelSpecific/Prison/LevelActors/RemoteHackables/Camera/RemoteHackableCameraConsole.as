UCLASS(Abstract)
class ARemoteHackableCameraConsole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ConsoleRoot;

	UPROPERTY(DefaultComponent, Attach = ConsoleRoot)
	URemoteHackingResponseComponent HackingComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableCameraCapability");

	TArray<ARemoteHackableCamera> Cameras;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cameras = TListedActors<ARemoteHackableCamera>().GetArray();
	}
}