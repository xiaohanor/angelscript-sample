
class USmasherMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"GroundMovement");	

	UGroundPathfollowingSettings GroundPathfollowingSettings;
	USteppingMovementData SteppingMovement;
	USummitSmasherPauseMovementComponent PauseComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GroundPathfollowingSettings = UGroundPathfollowingSettings::GetSettings(Owner);
		SteppingMovement = Cast<USteppingMovementData>(Movement);
		PauseComp = USummitSmasherPauseMovementComponent::Get(Owner);
	}

	UBaseMovementData SetupMovementData() override
	{
		return MoveComp.SetupSteppingMovementData();
	} 

	bool PrepareMove() override
	{
		return MoveComp.PrepareMove(SteppingMovement);
	}

	void ApplyCrumbSyncedMovement(FVector Velocity) override
	{
		Movement.ApplyCrumbSyncedGroundMovementWithCustomVelocity(Velocity);			
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		// Clear any pause when starting normal move, any pausing should be turned on after
		PauseComp.MovementPausers.Reset();
	}

	void ComposeMovement(float DeltaTime) override
	{	
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
#endif

		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		Velocity -= CustomVelocity; 

		FVector Destination = GetCurrentDestination();
		FVector HorizontalVelocity = Velocity.ConstrainToPlane(MoveComp.WorldUp);
		FVector VerticalVelocity = Velocity - HorizontalVelocity;
		FVector MoveDir = (Destination - OwnLoc).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

#if !RELEASE
		TemporalLog.Sphere("Initial;OwnLoc", OwnLoc, 50, FLinearColor::LucBlue);
		TemporalLog.DirectionalArrow("Initial;Velocity", OwnLoc, Velocity);
		TemporalLog.Sphere("Initial;Destination", Destination, 50, FLinearColor::Green);
		TemporalLog.DirectionalArrow("Initial;HorizontalVelocity", OwnLoc, HorizontalVelocity);
		TemporalLog.DirectionalArrow("Initial;VerticalVelocity", OwnLoc, VerticalVelocity);
		TemporalLog.DirectionalArrow("Initial;MoveDir", OwnLoc, MoveDir);
		TemporalLog.Value("Initial;HasDestination", DestinationComp.HasDestination());
#endif
		
		PauseComp.bWantsToMove = true;
		if (PauseComp.MovementPausers.Num() > 0)
		{
			// Stop and ignore destination until movement is allowed again
			HorizontalVelocity -= HorizontalVelocity * 20.0 * DeltaTime;
			Movement.AddVelocity(HorizontalVelocity);
			VerticalVelocity -= VerticalVelocity * MoveSettings.AirFriction * DeltaTime;
	
			// Count as wanting to move here, we won't move until allowed anyway
			PauseComp.bWantsToMove = true;
		}
		else if (DestinationComp.HasDestination()) 
		{
			float MoveSpeed = DestinationComp.Speed;
			FHazeAcceleratedVector AccLocation;
			AccLocation.SnapTo(OwnLoc, HorizontalVelocity);

#if !RELEASE
			TemporalLog.Value("HasDestination;MoveSpeed", MoveSpeed);
#endif
			if (IsMovingToFinalDestination() && OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			{
				// Slow to a stop
				AccLocation.AccelerateTo(Destination, 1.0, DeltaTime);
				
				// Keep applying slowed down velocity until we're moving away from destination 
				// TODO: this can be handled better, but will at least stop overshoot sliding on slopes.
				if (MoveDir.DotProduct(HorizontalVelocity) > 0.0) 
					Movement.AddVelocity(HorizontalVelocity);

				// MoveTo is completed (note that this will usually mean this capability will deactivate)
				PathFollowingComp.ReportComplete(true);
				PauseComp.bWantsToMove = false;

#if !RELEASE
				TemporalLog.Status("Slow to a Stop", FLinearColor::Red);
				TemporalLog.Sphere("HasDestination;AccLocation Value", AccLocation.Value, 50);
				TemporalLog.DirectionalArrow("HasDestination;AccLocation Velocity", AccLocation.Value, AccLocation.Velocity);
#endif
			}
			else
			{
				// Move towards destination
				AccLocation.AccelerateTo(OwnLoc + MoveDir * MoveSpeed, GroundPathfollowingSettings.AccelerationDuration, DeltaTime);
				const FVector ClampedVelocity = AccLocation.Velocity.GetClampedToMaxSize(MoveSpeed); // Hacky clamp but this will be replaced
				Movement.AddVelocity(ClampedVelocity);
				
#if !RELEASE
				TemporalLog.Status("Move towards destination", FLinearColor::Green);
				TemporalLog.Sphere("HasDestination;AccLocation Value", AccLocation.Value, 50);
				TemporalLog.DirectionalArrow("HasDestination;AccLocation Velocity", AccLocation.Value, AccLocation.Velocity);
				TemporalLog.DirectionalArrow("HasDestination;ClampedVelocity", OwnLoc, ClampedVelocity);
#endif
			}
		}
		else
		{
			// No destination, slow to a stop
			DestinationComp.ReportStopping();
			float Friction = MoveComp.IsInAir() ? MoveSettings.AirFriction : MoveSettings.GroundFriction;
			HorizontalVelocity -= HorizontalVelocity * Friction * DeltaTime;
			Movement.AddVelocity(HorizontalVelocity);
			VerticalVelocity -= VerticalVelocity * Friction * DeltaTime;
			PauseComp.bWantsToMove = false;

#if !RELEASE
			TemporalLog.Status("No destination, slow to a stop", FLinearColor::Yellow);
#endif
		}

		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		float Friction = MoveComp.IsOnWalkableGround() ? MoveSettings.GroundFriction : MoveSettings.AirFriction;
		CustomVelocity -= CustomVelocity * Friction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);

#if !RELEASE
		TemporalLog.DirectionalArrow("Final;CustomVelocity", OwnLoc, CustomVelocity);
#endif

		if (PauseComp.MovementPausers.Num() == 0)
		{
			// Turn towards focus?
			if (DestinationComp.Focus.IsValid())
				MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
			// Turn towards destination if still some ways off
			else if (DestinationComp.HasDestination() && !OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
				MoveComp.RotateTowardsDirection(MoveDir, MoveSettings.TurnDuration, DeltaTime, Movement);
			// Slow to a stop
			else  
				MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);
		}

		Movement.AddPendingImpulses();
		Movement.AddVelocity(VerticalVelocity);
		Movement.AddGravityAcceleration();
	}
}

class USummitSmasherPauseMovementComponent : UActorComponent
{
	TArray<FInstigator> MovementPausers;
	bool bWantsToMove = true;
} 

class USummitSmasherPauseMovementAnimNotifyState : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		if ((MeshComp == nullptr) || (MeshComp.Owner == nullptr))
			return false;
		USummitSmasherPauseMovementComponent PauseComp = USummitSmasherPauseMovementComponent::Get(MeshComp.Owner);
		if (PauseComp == nullptr)
			return false;
		PauseComp.MovementPausers.AddUnique(MeshComp);
		return true;	
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if ((MeshComp == nullptr) || (MeshComp.Owner == nullptr))
			return false;
		USummitSmasherPauseMovementComponent PauseComp = USummitSmasherPauseMovementComponent::Get(MeshComp.Owner);
		if (PauseComp == nullptr)
			return false;
		PauseComp.MovementPausers.Remove(MeshComp);
		return true;	
	}
}

