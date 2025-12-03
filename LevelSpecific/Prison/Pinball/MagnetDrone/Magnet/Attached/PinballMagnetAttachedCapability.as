class UPinballMagnetAttachedCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneAttachToSurface);

	default TickGroup = MagnetDrone::AttachToTickGroup;
	default TickGroupOrder = MagnetDrone::AttachToTickGroupOrder;
	default TickGroupSubPlacement = 100;

	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttachedComponent AttachedComp;
	UMagnetDroneAttractionComponent AttractionComp;

	UHazeMovementComponent MoveComp;
    USweepingMovementData MoveData; 

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);

        MoveComp = UHazeMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(!AttachedComp.IsAttachedToSurface())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AttachedComp.IsAttachedToSurface())
			return true;

		const UDroneMagneticSurfaceComponent SurfaceComp = AttachedComp.AttachedData.GetSurfaceComp();
		if(SurfaceComp.bImmediatelyDetach)
			return true;

		if(!IsActioning(MagnetDrone::MagnetInput))
			return true;

		// If we are limited to magnetizing within the zones, check if we are in at least one zone
		if(SurfaceComp.ShouldFallOffFromZones(DroneComp.GetDroneCenterLocation()))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive())
		{
			if(DeactiveDuration > 1.0)
			{
				AttachedComp.AttachedData.ResetWasRecentlyAttached();
			}
			else if(!IsActioning(MagnetDrone::MagnetInput))
			{
				AttachedComp.AttachedData.ResetWasRecentlyAttached();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// enable Tyko special movement magic
		// prevent the drone from rolling off the edge (even with super high velocity)
		Player.AddMovementAlignsWithAnyContact( this, bCanFallOfEdges = false);

		UMovementSweepingSettings::SetRemainOnGroundMinTraceDistance(
			Player,
			FMovementSettingsValue::MakePercentage(MagnetDrone::MagnetGroundTraceDistanceCantFallOff),
			this,
			EHazeSettingsPriority::Gameplay
		);

		Player.BlockCapabilitiesExcluding(DroneCommonTags::DroneDashCapability, MagnetDroneTags::MagnetDroneSurfaceDash, this);
		
		MoveComp.Reset(true, AttachedComp.AttachedData.GetInitialTargetImpactNormal(), true);
		MoveComp.SnapToGround(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveMovementAlignsWithAnyContact(this);

		MoveComp.ClearCurrentGroundedState();
		
		UMovementSweepingSettings::ClearRemainOnGroundMinTraceDistance(Player, this, EHazeSettingsPriority::Gameplay);

		if(AttachedComp.AttachedData.CanAttach())
			AttachedComp.Detach(n"Pinball_AttachToSurface_Deactivated");

		Player.UnblockCapabilities(DroneCommonTags::DroneDashCapability, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			AttachedComp.UpdateNewGroundContact(false);
	}
}