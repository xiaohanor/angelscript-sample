class UMagnetDroneAttachedToSocketCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneAttachToSocket);

	default TickGroup = MagnetDrone::AttachToTickGroup;
	default TickGroupOrder = MagnetDrone::AttachToTickGroupOrder;
	default TickGroupSubPlacement = 100;

	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttachedComponent AttachedComp;
	UMagnetDroneAttractionComponent AttractionComp;

	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Owner);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Owner);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Owner);

        MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AttachedComp.IsAttachedToSocket())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AttachedComp.IsAttachedToSocket())
		{
			TEMPORAL_LOG(AttachedComp).Event("AttachToSocket deactivated from !IsAttachedToSocket");
			return true;
		}

		const UDroneMagneticSocketComponent SocketComp = AttachedComp.AttachedData.GetSocketComp();

		if(SocketComp.bImmediatelyDetach)
		{
			TEMPORAL_LOG(AttachedComp).Event("AttachToSocket deactivated from bImmediatelyDetach");
			return true;
		}

		if(SocketComp.bAllowDeattaching)
		{
			if(SocketComp.bDetachByToggle)
			{
				if(WasActionStarted(MagnetDrone::MagnetInput))
				{
					TEMPORAL_LOG(AttachedComp).Event("AttachToSocket deactivated from MagnetInput toggle");
					return true;
				}
			}
			else if(!IsActioning(MagnetDrone::MagnetInput))
			{
				TEMPORAL_LOG(AttachedComp).Event("AttachToSocket deactivated from no MagnetInput");
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Smooth out the camera transition
		Player.ApplyBlendToCurrentView(1.0);

		MoveComp.Reset(
			true,
			AttachedComp.AttachedData.GetInitialTargetImpactNormal(),
			false
		);

		UTeleportResponseComponent::GetOrCreate(Player).OnTeleported.AddUFunction(this, n"OnTeleported");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(AttachedComp.AttachedData.IsValid())
			AttachedComp.Detach(n"AttachToSocket_Deactivated");
		
		// Smooth out the camera transition
		Player.ApplyBlendToCurrentView(1.0);

		UTeleportResponseComponent::GetOrCreate(Player).OnTeleported.Unbind(this, n"OnTeleported");
	}

	UFUNCTION()
	private void OnTeleported()
	{
		AttachedComp.Detach(n"OnTeleported");
	}
}