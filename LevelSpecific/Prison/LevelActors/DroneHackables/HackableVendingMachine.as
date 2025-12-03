class AHackableVendingMachine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeCameraComponent CameraComp;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LaunchPositionComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf <AVendingMachineCan> VendingMachineCan;

	UPROPERTY()
	FSwarmHijackStartEvent OnHackingStarted;

	UPROPERTY()
	FSwarmHijackStopEvent OnHackingStopped;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USwarmDroneHijackTargetableComponent HijackableTarget;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HackableVendingMachineCapability");

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CapabilityInput::LinkActorToPlayerInput(this, Drone::GetSwarmDronePlayer());
	}
}

class UHackableVendingMachineCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 105;

	AHazePlayerCharacter PlayerComp;
	UHazeMovementComponent PlayerMoveComp;

	AHackableVendingMachine VendingMachine;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Print("Set");
		VendingMachine = Cast<AHackableVendingMachine>(Owner);
		PlayerComp = Drone::GetSwarmDronePlayer();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!VendingMachine.HijackableTarget.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (VendingMachine.HijackableTarget.IsHijacked())
			return false;

		return true;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerComp.ActivateCamera(VendingMachine.CameraComp, 1, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Drone::GetSwarmDronePlayer().DeactivateCamera(VendingMachine.CameraComp, 1);
		Drone::GetSwarmDronePlayer().SnapCameraBehindPlayer();
	}
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::PrimaryLevelAbility))
		{
			AVendingMachineCan Can = SpawnActor(VendingMachine.VendingMachineCan,VendingMachine.LaunchPositionComp.GetWorldLocation(), VendingMachine.LaunchPositionComp.GetWorldRotation());			
		}
	}
}
