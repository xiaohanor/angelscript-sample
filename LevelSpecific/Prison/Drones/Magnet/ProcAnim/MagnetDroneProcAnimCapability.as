class UMagnetDroneProcAnimCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneProcAnim);

	default BlockExclusionTags.Add(MagnetDroneTags::AttachToBoatBlockExclusionTag);

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 120;

	UMagnetDroneComponent DroneComp;
	UMagnetDroneProcAnimComponent ProcAnimComp;
	UMagnetDroneJumpComponent JumpComp;
	UMagnetDroneAttachedComponent AttachedComp;

	UPoseableMeshComponent DroneMesh;
	UHazeMovementComponent MoveComp;

	bool bHasInitialized = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ProcAnimComp = UMagnetDroneProcAnimComponent::Get(Owner);
		DroneComp = UMagnetDroneComponent::Get(Owner);
		JumpComp = UMagnetDroneJumpComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DroneComp.GetDroneMeshComponent() == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DroneComp.GetDroneMeshComponent() == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DroneMesh = Cast<UPoseableMeshComponent>(DroneComp.GetDroneMeshComponent());

		if(!bHasInitialized)
		{
			ProcAnimComp.Reset(DroneMesh);

			auto RespawnComp = UPlayerRespawnComponent::Get(Player);
			RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawned");
			
			bHasInitialized = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		const FVector ForwardVelocity = MoveComp.Velocity.ProjectOnToNormal(Player.ActorForwardVector);
		const float SpeedFactor = Math::Clamp(ForwardVelocity.Size() / MagnetDrone::ShellSettings::SpeedMultiplier, 0.0, 1.0);
		const float JumpDuration = JumpComp.IsJumping() ? JumpComp.GetJumpDuration() : 0;
		const FVector SocketNormal = AttachedComp.IsAttachedToSocket() ? AttachedComp.AttachedData.GetSocketNormal() : FVector::ZeroVector;

		ProcAnimComp.TickProceduralAnimation(
			DroneMesh,
			DeltaTime,
			JumpComp.IsJumping(),
			JumpDuration,
			MoveComp.WorldUp,
			MoveComp.IsOnWalkableGround(),
			AttachedComp.IsAttachedToSocket(),
			SocketNormal,
			ActiveDuration,
			SpeedFactor,
			DroneComp.bIsMagnetic
		);
	}

	UFUNCTION()
	private void OnPlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		ProcAnimComp.Reset(DroneMesh);
	}
}