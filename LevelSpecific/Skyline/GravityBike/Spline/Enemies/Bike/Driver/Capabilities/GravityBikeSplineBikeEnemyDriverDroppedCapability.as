struct FGravityBikeSplineBikeEnemyDriverDroppedDeactivateParams
{
	bool bTimedOut = false;
};

class UGravityBikeSplineBikeEnemyDriverDroppedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeSplineBikeEnemyDriver Driver;
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;
	FVector RotateAxis;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Driver = Cast<AGravityBikeSplineBikeEnemyDriver>(Owner);
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
	bool ShouldDeactivate(FGravityBikeSplineBikeEnemyDriverDroppedDeactivateParams& Params) const
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
		Driver.State = EGravityBikeSplineBikeEnemyDriverState::Dropped;
		RotateAxis = Math::GetRandomPointInSphere().GetSafeNormal();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineBikeEnemyDriverDroppedDeactivateParams Params)
	{
		GrabTargetComp.Reset();

		if(Params.bTimedOut)
		{
			Driver.DestroyActor();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Velocity = Driver.ActorVelocity;
		Velocity -= FVector::UpVector * (Driver.Gravity * DeltaTime);
		Driver.SetActorVelocity(Velocity);
		
		FVector Delta = Driver.ActorVelocity * DeltaTime;
		FVector Location = Driver.ActorLocation + Delta;

		if(HasControl())
		{
			TArray<AActor> IgnoredActors;
			IgnoredActors.Add(Driver.Bike);
			FHitResult HitResult = Driver.ThrowableComp.ThrowTrace(IgnoredActors, Driver.ActorLocation, Location);

			if(HitResult.bBlockingHit && HitResult.Actor != nullptr)
			{
				FGravityBikeWhipThrowHitData HitData;
				HitData.HitActor = HitResult.Actor;
				HitData.ImpactPoint = HitResult.ImpactPoint;
				HitData.ImpactNormal = HitResult.ImpactNormal;
				Driver.ThrowableComp.CrumbOnThrowHit(HitData);
			}
			else
			{
				Driver.SetActorLocation(Location);
				Driver.AddActorLocalRotation(FQuat(RotateAxis, 10 * DeltaTime));
			}
		}
		else
		{
			Driver.SetActorLocation(Location);
			Driver.AddActorLocalRotation(FQuat(RotateAxis, 10 * DeltaTime));
		}
	}
};