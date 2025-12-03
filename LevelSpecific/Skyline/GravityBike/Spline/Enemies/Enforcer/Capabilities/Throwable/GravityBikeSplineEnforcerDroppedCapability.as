struct FGravityBikeSplineEnforcerDroppedDeactivateParams
{
	bool bTimedOut = false;
};

class UGravityBikeSplineEnforcerDroppedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeSplineEnforcer Enforcer;
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;
	FVector RotateAxis;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enforcer = Cast<AGravityBikeSplineEnforcer>(Owner);
		GrabTargetComp = Enforcer.GrabTargetComp;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GrabTargetComp.GrabState != EGravityBikeWhipGrabState::Dropped)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeSplineEnforcerDroppedDeactivateParams& Params) const
	{
		if(GrabTargetComp.GrabState != EGravityBikeWhipGrabState::Dropped)
			return true;

		if(ActiveDuration > 5)
		{
			Params.bTimedOut = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Enforcer.State = EGravityBikeSplineEnforcerState::Dropped;
		RotateAxis = Math::GetRandomPointInSphere().GetSafeNormal();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineEnforcerDroppedDeactivateParams Params)
	{
		GrabTargetComp.Reset();

		if(Params.bTimedOut)
		{
			Enforcer.DestroyActor();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Velocity = Enforcer.ActorVelocity;
		Velocity -= FVector::UpVector * (Enforcer.Gravity * DeltaTime);
		Enforcer.SetActorVelocity(Velocity);
		
		FVector Delta = Enforcer.ActorVelocity * DeltaTime;
		FVector Location = Enforcer.ActorLocation + Delta;

		if(HasControl())
		{
			TArray<AActor> IgnoredActors;
			FHitResult HitResult = Enforcer.ThrowableComp.ThrowTrace(IgnoredActors, Enforcer.ActorLocation, Location);

			if(HitResult.bBlockingHit && HitResult.Actor != nullptr)
			{
				FGravityBikeWhipThrowHitData HitData;
				HitData.HitActor = HitResult.Actor;
				HitData.ImpactPoint = HitResult.ImpactPoint;
				HitData.ImpactNormal = HitResult.ImpactNormal;
				Enforcer.ThrowableComp.CrumbOnThrowHit(HitData);
			}
			else
			{
				Enforcer.SetActorLocation(Location);
				Enforcer.AddActorLocalRotation(FQuat(RotateAxis, 10 * DeltaTime));
			}
		}
		else
		{
			Enforcer.SetActorLocation(Location);
			Enforcer.AddActorLocalRotation(FQuat(RotateAxis, 10 * DeltaTime));
		}
	}
};