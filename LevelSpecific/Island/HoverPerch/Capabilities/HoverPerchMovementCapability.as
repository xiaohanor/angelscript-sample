class UHoverPerchMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 190;

	UHazeMovementComponent MoveComp;
	UPlayerMovementComponent PlayerMoveComp;
	USweepingMovementData Movement;

	AHoverPerchActor PerchActor;

	FHazeAcceleratedVector AcceleratedSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();

		PerchActor = Cast<AHoverPerchActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(PerchActor.HoverPerchComp.bIsDestroyed)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(PerchActor.HoverPerchComp.bIsDestroyed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.OverrideResolver(UHoverPerchActorSweepingResolver, this);

		AcceleratedSpeed.SnapTo(PerchActor.ActorVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ClearResolverOverride(UHoverPerchActorSweepingResolver, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				AcceleratedSpeed.AccelerateTo(MoveComp.MovementInput * PerchActor.MaxSpeedWhileOnPerch, 1.0, DeltaTime);

				FVector MovementImpulse = MoveComp.PendingImpulse;
				Movement.AddPendingImpulses();

				AcceleratedSpeed.SnapTo(AcceleratedSpeed.Value + MovementImpulse);

				PerchActor.MeshComp.AddLocalRotation(FRotator(0, (AcceleratedSpeed.Value.Size() / 2) * DeltaTime, 0));
				PerchActor.SyncedMeshRelativeRotation.Value = PerchActor.MeshComp.RelativeRotation;

				FVector TargetLocation = PerchActor.ActorLocation - AcceleratedSpeed.Value * DeltaTime;

				FVector DeltaMove = PerchActor.ActorLocation - TargetLocation;
				Movement.AddDelta(DeltaMove);

				PerchActor.ApplyHeightResetMovement(Movement, DeltaTime);

				TEMPORAL_LOG(PerchActor)
					.DirectionalArrow("Accelerated Speed", PerchActor.ActorLocation, AcceleratedSpeed.Value, 5, 40, FLinearColor::Blue)
				;
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
				PerchActor.MeshComp.RelativeRotation = PerchActor.SyncedMeshRelativeRotation.Value;
			}

			MoveComp.ApplyMove(Movement);
		}

		if(HasControl() && PerchActor.PlayerLocker != nullptr)
		{
			PerchActor.BodyMeshComp.WorldRotation = PerchActor.PlayerLocker.ActorRotation;
			PerchActor.SyncedBodyMeshWorldRotation.Value = PerchActor.BodyMeshComp.WorldRotation;
		}
		else if(!HasControl())
		{
			PerchActor.BodyMeshComp.WorldRotation = PerchActor.SyncedBodyMeshWorldRotation.Value;
		}
	}
};