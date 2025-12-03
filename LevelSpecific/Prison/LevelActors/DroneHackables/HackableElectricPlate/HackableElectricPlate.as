class AHackableElectricPlate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HackableRoot;

	UPROPERTY(DefaultComponent, Attach = HackableRoot)
	UStaticMeshComponent HackableMeshComp;

	UPROPERTY(DefaultComponent, Attach = HackableRoot)
	USwarmDroneHijackTargetableComponent HijackTargetableComp;

	UPROPERTY()
	FSwarmHijackStartEvent OnHackingStarted;

	UPROPERTY()
	FSwarmHijackStopEvent OnHackingStopped;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HackableElectricPlateCapability");

	
	UFUNCTION(NotBlueprintCallable)
	private void HackingStarted(FSwarmDroneHijackParams HijackParams)
	{
		OnHackingStarted.Broadcast(HijackParams);
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackingStopped()
	{
		OnHackingStopped.Broadcast();
	}
}