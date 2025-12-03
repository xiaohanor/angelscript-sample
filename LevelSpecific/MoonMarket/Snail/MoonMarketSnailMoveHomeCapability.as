class UMoonMarketSnailMoveHomeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;

	AMoonMarketSnail Snail;
	UHazeMovementComponent MoveComp;
	UPolymorphResponseComponent PolymorphComp;
	USteppingMovementData MoveData;

	const float GroundOffset = 10;

	float CurrentSpineYaw = 0;
	FQuat CurrentSpineRotation;
	float MoveSpeed = 0;

	FHazeRuntimeSpline NavigationSpline;

	bool bStuck = false;
	float StartStuckTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Snail = Cast<AMoonMarketSnail>(Owner);
		MoveComp = Snail.MoveComp;
		MoveData = MoveComp.SetupSteppingMovementData();
		PolymorphComp = UPolymorphResponseComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Snail.InteractingPlayer != nullptr)
			return false;

		if(Snail.bIsHome)
			return false;

		if(PolymorphComp.ShapeshiftComp.ShapeshiftShape != nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Snail.InteractingPlayer != nullptr)
			return true;

		if(Snail.bIsHome)
			return true;

		if(PolymorphComp.ShapeshiftComp.ShapeshiftShape != nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		float DistToTarget = Snail.ActorLocation.Dist2D(Snail.OriginalPosition);
		if(DistToTarget < 70)
		{
			Snail.bIsHome = true;
			return;
		}

		Snail.bIsHome = false;

		if(HasControl())
		{
			bStuck = false;
			MoveSpeed = Snail.ActorVelocity.Z;

			const UNavigationPath Path = UNavigationSystemV1::FindPathToLocationSynchronously(Owner.ActorLocation, Snail.OriginalPosition);
			
			if(Path != nullptr && Path.IsValid())
			{
				NavigationSpline.SetPoints(Path.PathPoints);
			}

			if(NavigationSpline.Points.IsEmpty())
				Snail.bIsHome = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(Snail.ActorLocation.Distance(Snail.OriginalPosition) < 70)
			Snail.bIsHome = true;

		Snail.SetActorVelocity(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl() && NavigationSpline.Points.IsEmpty())
			return;

		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			if(ActiveDuration > 1)
			{
				if(bStuck)
				{
					if(MoveComp.Velocity.Size() > 10)
						bStuck = false;

					if(Time::GetGameTimeSince(StartStuckTime) >= 5)
						Snail.bIsHome = true;
				}
				else if(MoveComp.Velocity.Size() < 10)
				{
					bStuck = true;
					StartStuckTime = Time::GameTimeSeconds;
				}
			}

			MoveData.AddOwnerVerticalVelocity();
			
			float CurrentDistance = NavigationSpline.GetClosestSplineDistanceToLocation(Snail.ActorLocation);
			FVector TargetDirection = (NavigationSpline.GetLocationAtDistance(CurrentDistance + 100) - Snail.ActorLocation).GetSafeNormal();

			float TargetMoveSpeed = Snail.MoveSpeed / 2;
			float DistToTarget = Snail.ActorLocation.Distance(Snail.OriginalPosition);
			if(DistToTarget < 300)
			{
				TargetMoveSpeed = Math::Lerp(TargetMoveSpeed, 10, (300 - DistToTarget) / 300);
				if(DistToTarget < 20)
					Snail.bIsHome = true;
			}

			MoveSpeed = Math::FInterpConstantTo(MoveSpeed, TargetMoveSpeed, DeltaTime, 100);
			FQuat ProjectedQuat = FQuat::MakeFromZX(MoveComp.WorldUp, TargetDirection);
			FQuat Rotation = Math::QInterpTo(Snail.GetActorQuat(), ProjectedQuat, DeltaTime, Snail.RotateSpeed);
			
			MoveData.SetRotation(Rotation);

			const FVector Velocity = Snail.ActorForwardVector * MoveSpeed;

			MoveData.AddHorizontalVelocity(Velocity);
			MoveData.AddGravityAcceleration();
		}
		else
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(MoveData);
		Snail.TrailComp.SetWorldLocation(Snail.SkelMeshComp.GetSocketLocation(n"Tail3"));
	}
};