struct FGravityBikeWhipThrowableDroppedDeactivateParams
{
	bool bDestroySelf = false;
}

class UGravityBikeWhipThrowableDroppedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UGravityBikeWhipThrowableComponent ThrowableComp;
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;

	FGravityBikeWhipThrowMoveData ThrowMoveData;
	bool bRelativeToGravityBikeSpline = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ThrowableComp = UGravityBikeWhipThrowableComponent::Get(Owner);
		GrabTargetComp = UGravityBikeWhipGrabTargetComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GrabTargetComp.GrabState != EGravityBikeWhipGrabState::Dropped)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeWhipThrowableDroppedDeactivateParams& Params) const
	{
		if(GrabTargetComp.GrabState != EGravityBikeWhipGrabState::Dropped)
			return true;

		if(ActiveDuration > ThrowableComp.ThrownLifeTime)
		{
			Params.bDestroySelf = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ThrowMoveData = FGravityBikeWhipThrowMoveData(Owner.ActorLocation, Owner.ActorVelocity, GravityBikeSpline::GetGravityBike());
		bRelativeToGravityBikeSpline = true;

		UGravityBikeWhipThrowableEventHandler::Trigger_OnDropped(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeWhipThrowableDroppedDeactivateParams Params)
	{
		if(Params.bDestroySelf)
		{
			Owner.DestroyActor();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ThrowMoveData.IsOnGravityBikeSpline())
			TickSplineMovement(DeltaTime);
		else
			TickWorldMovement(DeltaTime);

		TickRotation(DeltaTime);
	}

	void TickSplineMovement(float DeltaTime)
	{
		bool bReachedEnd = false;
		ThrowMoveData.Tick(DeltaTime, bReachedEnd);

		if(bReachedEnd)
		{
			if(HasControl())
			{
				FGravityBikeWhipThrowHitData HitData;
				HitData.HitActor = GrabTargetComp.GetThrowTarget().Owner;
				HitData.ImpactPoint = GrabTargetComp.GetThrowTargetWorldLocation();
				HitData.ImpactNormal = -Owner.ActorVelocity.GetSafeNormal();
				ThrowableComp.CrumbOnThrowHit(HitData);
			}
			else
			{
				FVector WorldLocation = GrabTargetComp.GetThrowTargetWorldLocation();
				FVector Velocity = (WorldLocation - Owner.ActorLocation) / DeltaTime;

				Move(WorldLocation, Velocity);
			}
		}
		else
		{
			FVector WorldLocation = ThrowMoveData.GetWorldLocation();
			FVector Velocity = (WorldLocation - Owner.ActorLocation) / DeltaTime;

			Move(WorldLocation, Velocity);
		}
	}

	void TickWorldMovement(float DeltaTime)
	{
		FVector Velocity = Owner.ActorVelocity;
		FVector Delta = Velocity * DeltaTime;
		Acceleration::ApplyAccelerationToVelocity(Velocity, FVector::DownVector * 1000, DeltaTime, Delta);
		const FVector WorldLocation = Owner.ActorLocation + Delta;

		Move(WorldLocation, Velocity);
	}

	void TickRotation(float DeltaTime)
	{
		Owner.AddActorLocalRotation(FQuat(FVector(0.5, 0.3, 0.7), 10 * DeltaTime));
	}

	bool Move(FVector Location, FVector Velocity)
	{
		if(!HasControl())
		{
			// No sweeping on remote, just snap
			Owner.SetActorLocation(Location);
			Owner.SetActorVelocity(Velocity);
			return false;
		}

		TArray<AActor> IgnoredActors;
		FHitResult HitResult = ThrowableComp.ThrowTrace(IgnoredActors, Owner.ActorLocation, Location);

		if(HitResult.bBlockingHit && IsValid(HitResult.Actor))
		{
			Owner.SetActorLocation(HitResult.Location);
			Owner.SetActorVelocity(Velocity);

			FGravityBikeWhipThrowHitData HitData;
			HitData.HitActor = HitResult.Actor;
			HitData.ImpactPoint = HitResult.ImpactPoint;
			HitData.ImpactNormal = HitResult.ImpactNormal;
			ThrowableComp.CrumbOnThrowHit(HitData);
			return true;
		}
		else
		{
			Owner.SetActorLocation(Location);
			Owner.SetActorVelocity(Velocity);
			return false;
		}
	}
};