class UMagnetDroneSocketMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneSocketMovement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 101;

	UMagnetDroneAttachedComponent AttachedComp;
	UHazeMovementComponent MoveComp;
    UMagnetDroneAttachedMovementData MoveData; 

	float TimeSpentAirborne = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(UMagnetDroneAttachedMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		// The attach capability will set this to true, flagging this capability to activate
		if(!AttachedComp.IsAttachedToSocket())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!AttachedComp.IsAttachedToSocket())
			return true;

		if(MoveComp.HasAnyValidBlockingImpacts())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// safety net timer incase the movement system fails
		TimeSpentAirborne = 0.0;

		// Zero out the velocity
		Player.SetActorVelocity(FVector::ZeroVector);

		MoveComp.FollowComponentMovement(AttachedComp.AttachedData.GetSocketComp(), this, EMovementFollowComponentType::Teleport);

		TArray<AActor> ActorsToIgnore;
		const UDroneMagneticSocketComponent MagneticSocketComponent = AttachedComp.AttachedData.GetSocketComp();
		ActorsToIgnore.Add(MagneticSocketComponent.Owner);
		ActorsToIgnore.Append(MagneticSocketComponent.IgnoredActors);
		MoveComp.AddMovementIgnoresActors(this, ActorsToIgnore);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AttachedComp.Detach(n"SocketMovement_Deactivated");

		MoveComp.UnFollowComponentMovement(this);

		MoveComp.RemoveMovementIgnoresActor(this);

		// FB TODO: Move this to AttachToSocketCapability, so that state is active during all of the attachment (similar to AttachToSurface)?
		Player.ApplyBlendToCurrentView(1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{	
		if(!HasControl() && !AttachedComp.AttachedData.CanAttach())
			return;
		
		if(!MoveComp.PrepareMove(MoveData, AttachedComp.AttachedData.GetSocketNormal()))
			return;

		if(HasControl())
		{
			const UDroneMagneticSocketComponent MagneticSocketComponent = AttachedComp.AttachedData.GetSocketComp();
			const FVector LockLocation = MagneticSocketComponent.WorldLocation;

			// No velocity (of course)
			MoveData.AddDeltaFromMoveToPositionWithCustomVelocity(LockLocation, FVector::ZeroVector);
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}
}	