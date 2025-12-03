struct FGravityBikeWhipThrowableThrownActivateParams
{
	bool bHasTarget = false;
	UGravityBikeWhipThrowTargetComponent ThrowTargetComp = nullptr;
	FVector ThrowDirection;
}

struct FGravityBikeWhipThrowableThrownDeactivateParams
{
	bool bDestroySelf = false;
}

class UGravityBikeWhipThrowableThrownCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UGravityBikeWhipThrowableComponent ThrowableComp;
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;

	FGravityBikeWhipThrowMoveData ThrowMoveData;
	bool bHasValidTarget = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ThrowableComp = UGravityBikeWhipThrowableComponent::Get(Owner);
		GrabTargetComp = UGravityBikeWhipGrabTargetComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeWhipThrowableThrownActivateParams& Params) const
	{
		if(GrabTargetComp.GrabState != EGravityBikeWhipGrabState::Thrown)
			return false;

		if(GrabTargetComp.HasThrowTarget())
		{
			Params.bHasTarget = true;
			Params.ThrowTargetComp = GrabTargetComp.GetThrowTarget();
		}
		else
		{
			Params.ThrowDirection = GrabTargetComp.GetWhipComponent().GetThrowCrosshairWorldDirection();
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeWhipThrowableThrownDeactivateParams& Params) const
	{
		if(GrabTargetComp.GrabState != EGravityBikeWhipGrabState::Thrown)
			return true;

		if(ActiveDuration > ThrowableComp.ThrownLifeTime)
		{
			Params.bDestroySelf = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeWhipThrowableThrownActivateParams Params)
	{
		check(Params.bHasTarget == IsValid(Params.ThrowTargetComp));

		FGravityBikeWhipThrowableThrownEventData EventData;
		EventData.ThrowTarget = Params.ThrowTargetComp;
		UGravityBikeWhipThrowableEventHandler::Trigger_OnThrown(Owner, EventData);

		auto GravityBike = GravityBikeSpline::GetGravityBike();

		if(IsValid(Params.ThrowTargetComp))
		{
			// InitializeThrowAtTarget calculates how to throw internally, so we just pass in some parameters
			ThrowMoveData = FGravityBikeWhipThrowMoveData(
				Owner.ActorLocation,
				Owner.ActorVelocity,
				ThrowableComp.ThrowAtTargetSpeed,
				ThrowableComp.ThrowArcHeightPerSecond,
				Params.ThrowTargetComp,
				GravityBike
			);

			bHasValidTarget = true;
		}
		else
		{
			// When throwing with no target, we manually calculate what velocity to use

			const FTransform SplineTransform = GravityBike.GetSplineTransform();
			FVector ThrowVelocity = Params.ThrowDirection * ThrowableComp.ThrowHorizontalSpeed + SplineTransform.Rotation.UpVector * ThrowableComp.ThrowVerticalSpeed;
			FVector BikeVelocity = GravityBike.ActorVelocity;
			ThrowVelocity += BikeVelocity;

			ThrowMoveData = FGravityBikeWhipThrowMoveData(Owner.ActorLocation, ThrowVelocity, GravityBike);

			bHasValidTarget = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeWhipThrowableThrownDeactivateParams Params)
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
		{
			if(bHasValidTarget && !IsTargetValid())
			{
				// Our target is no longer valid!
				bHasValidTarget = false;

				// Change our throw data to be in world space (ish)
				auto GravityBike = GravityBikeSpline::GetGravityBike();
				const FVector ThrowVelocity = Owner.ActorVelocity;
				ThrowMoveData = FGravityBikeWhipThrowMoveData(Owner.ActorLocation, ThrowVelocity, GravityBike);
			}

			TickSplineMovement(DeltaTime);
		}
		else
		{
			TickWorldMovement(DeltaTime);
		}

		TickRotation(DeltaTime);
	}

	void TickSplineMovement(float DeltaTime)
	{
		bool bReachedEnd = false;
		ThrowMoveData.Tick(DeltaTime, bReachedEnd);

		if(bReachedEnd && bHasValidTarget)
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
				Owner.SetActorLocation(ThrowMoveData.GetWorldLocation());
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
		if (ThrowableComp.bAimDirection)
		{
			FQuat TargetRotation = FQuat::MakeFromXZ(Owner.ActorVelocity, GravityBikeSpline::GetGlobalUp());
			TargetRotation = FQuat::ApplyDelta(TargetRotation, FQuat(Owner.ActorVelocity.GetSafeNormal(), 10 * ActiveDuration));
			Owner.SetActorRotation(TargetRotation);
		}
		else
		{
			Owner.AddActorLocalRotation(FQuat(FVector(0.5, 0.3, 0.7), 10 * DeltaTime));
		}
	}

	bool IsTargetValid() const
	{
		if(ThrowMoveData.ThrowTarget == nullptr)
			return false;

		if(ThrowMoveData.ThrowTarget.Owner.IsActorDisabled())
			return false;

		auto EnemyHealthComp = UGravityBikeSplineEnemyHealthComponent::Get(ThrowMoveData.ThrowTarget.Owner);
		if(EnemyHealthComp != nullptr && EnemyHealthComp.IsDead())
			return false;

		if(ThrowMoveData.ThrowTarget.IsDisabledForPlayer(GravityBikeWhip::GetPlayer()))
			return false;

		return true;
	}

	bool Move(FVector Location, FVector Velocity)
	{
		if(!HasControl())
		{
			Owner.SetActorLocation(Location);
			Owner.SetActorVelocity(Velocity);
			return false;
		}

		TArray<AActor> IgnoredActors;
		FHitResult HitResult = ThrowableComp.ThrowTrace(IgnoredActors, Owner.ActorLocation, ThrowMoveData.GetWorldLocation());

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