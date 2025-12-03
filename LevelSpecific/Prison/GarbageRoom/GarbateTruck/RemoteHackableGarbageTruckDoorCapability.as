class URemoteHackableGarbageTruckDoorCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	AGarbageTruck GarbageTruck;

	float FirstTimeOpenedAngleThreshold = 15.0;
	bool bFirstTimeOpened = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		GarbageTruck = Cast<AGarbageTruck>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UGarbageTruckEffectEventHandler::Trigger_DoorOpening(GarbageTruck);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UGarbageTruckEffectEventHandler::Trigger_DoorClosing(GarbageTruck);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (GarbageTruck.bLockPlayersIn)
			return;

		TickDoorControl();

		if (GarbageTruck.BottomRightHatch.RelativeRotation.Roll > -89.0 && GarbageTruck.BottomRightHatch.RelativeRotation.Roll < -1.0)
			Player.SetFrameForceFeedback(0.1, 0.1, 0.0, 0.0);

		if (!bFirstTimeOpened)
		{
			if (GarbageTruck.BottomRightHatch.RelativeRotation.Roll < -FirstTimeOpenedAngleThreshold)
			{
				bFirstTimeOpened = true;
				UGarbageTruckEffectEventHandler::Trigger_FirstTimeOpen(GarbageTruck);
			}
		}
	}

	private void TickDoorControl()
	{
		bool bHighEnough = GarbageTruck.ActorLocation.Z > GarbageTruck.StartLocation.Z + 700.0;
		PrintToScreen(" "+ bHighEnough);
		int ForceDirection = IsActive() && bHighEnough ? -1 : 1;
		float Force = IsActive() ? 10.0 : 20.0;
		if (!GarbageTruck.HackingComp.bHacked)
			Force = 30.0;

		GarbageTruck.BottomRightHatch.ApplyAngularForce(-Force * ForceDirection);
		GarbageTruck.BottomLeftHatch.ApplyAngularForce(Force * ForceDirection);
	}
}