class UMagnetDroneAttachedToSurfaceCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
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
	UMagnetDroneJumpComponent JumpComp;

	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		JumpComp = UMagnetDroneJumpComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);

        MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AttachedComp.IsAttachedToSurface())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AttachedComp.IsAttachedToSurface())
		{
#if !RELEASE
			TEMPORAL_LOG(AttachedComp).Event("AttachToSurface deactivated from !IsAttachedToSurface");
#endif
			return true;
		}

		if(AttachedComp.AttachedData.GetSurfaceComp().bImmediatelyDetach)
		{
#if !RELEASE
			TEMPORAL_LOG(AttachedComp).Event("AttachToSurface deactivated from bImmediatelyDetach");
#endif
			return true;
		}

		if(!IsActioning(MagnetDrone::MagnetInput))
		{
#if !RELEASE
			TEMPORAL_LOG(AttachedComp).Event("AttachToSurface deactivated from no input");
#endif
			return true;
		}

		// If we are limited to magnetizing within the zones, check if we are in at least one zone
		const UDroneMagneticSurfaceComponent MagneticSurfaceComponent = AttachedComp.AttachedData.GetSurfaceComp();
		if(MagneticSurfaceComponent.ShouldFallOffFromZones(DroneComp.GetDroneCenterLocation()))
		{
#if !RELEASE
			TEMPORAL_LOG(AttachedComp).Event("AttachToSurface deactivated from fall off zone");
#endif

			return true;
		}

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

		MoveComp.Reset(
			true,
			AttachedComp.AttachedData.GetInitialTargetImpactNormal(),
			false
		);
		
		MoveComp.SnapToGround(true, MagnetDrone::Radius);

		// Smooth out the camera transition
		Player.ApplyBlendToCurrentView(1.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveMovementAlignsWithAnyContact(this);
		UMovementSweepingSettings::ClearRemainOnGroundMinTraceDistance(Player, this, EHazeSettingsPriority::Gameplay);
		MoveComp.ClearCurrentGroundedState();

		if(AttachedComp.AttachedData.IsValid())
			AttachedComp.Detach(n"AttachToSurface_Deactivated");

		Player.UnblockCapabilities(DroneCommonTags::DroneDashCapability, this);
		
		// Smooth out the camera transition
		Player.ApplyBlendToCurrentView(1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			AttachedComp.UpdateNewGroundContact(true);
	}
}