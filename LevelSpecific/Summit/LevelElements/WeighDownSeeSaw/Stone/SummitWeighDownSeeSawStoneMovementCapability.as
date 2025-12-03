class USummitWeighDownSeeSawStoneMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	ASummitWeighDownSeeSawStone Stone;

	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Stone = Cast<ASummitWeighDownSeeSawStone>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(Stone.bHasHitSeeSaw)
			return false;

		if(!Stone.bHasBeenHit)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(Stone.bHasHitSeeSaw)
			return true;

		if(!Stone.bHasBeenHit)
			return true;
	
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FHazeTraceSettings DownTrace;
			DownTrace.TraceWithComponent(Stone.SphereComp);
			DownTrace.UseLine();
			DownTrace.IgnoreActor(Stone);
			FVector Start = Stone.ActorLocation;
			FVector End = Start + MoveComp.GravityDirection * 500.0;

			auto Hit = DownTrace.QueryTraceSingle(Start, End);
			TEMPORAL_LOG(Stone)
				.HitResults("Down Trace", Hit, FHazeTraceShape::MakeLine())
			;
			if(!Hit.bBlockingHit)
			{
				FVector TargetLocation = Stone.SeeSaw.TargetRoot.WorldLocation;
				FVector Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Stone.ActorLocation, TargetLocation, SummitWeighDownSeeSawStoneGravitySettings.GravityAmount, Stone.HorizontalSpeed);
				Stone.SetActorVelocity(Velocity);
			}
		}

		if (Stone.AttachParentActor == nullptr
		&& MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				if(!Stone.ActorVelocity.IsNearlyZero())
					Stone.KillPlayerInFront(Stone.ActorVelocity.GetSafeNormal());
				Movement.AddGravityAcceleration();

				Movement.AddOwnerVelocity();
				Movement.AddPendingImpulses();

				
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			if(HasControl())
			{
				auto Impacts = MoveComp.GetAllImpacts();
				for(auto Impact : Impacts)
				{
					auto SeeSaw = Cast<ASummitWeighDownSeeSaw>(Impact.Actor);
					if(SeeSaw == nullptr)
						continue;

					TEMPORAL_LOG(Stone)
						.Sphere("See Saw Impact", Impact.ImpactPoint, 100, FLinearColor::Black, 20)
					;

					Crumb_AttachToSeeSaw(SeeSaw, Impact.ImpactPoint);
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void Crumb_AttachToSeeSaw(ASummitWeighDownSeeSaw SeeSaw, FVector ImpactPoint)
	{
		Stone.AddActorTickBlock(this);
		Stone.ActorVelocity = FVector::ZeroVector;				
		// MoveComp.FollowComponentMovement(SeeSaw.RightPlatformRoot, this);		
		Stone.AttachToComponent(SeeSaw.RightPlatformRoot, n"NAME_None", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepRelative, true);
		SeeSaw.GetHitByStone(ImpactPoint);
		SeeSaw.bStoneIsAttached = true;
		Stone.bHasHitSeeSaw = true;
	}	
};