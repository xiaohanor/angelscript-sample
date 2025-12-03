class UHighwayEnforcerFitnessCircleStrafeBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);	

	bool bTriedBothDirections = false;
	bool bHadVisibility;
	float Radius;
	bool bShouldStrafe;
	float ShouldStrafeTime;
	float ShouldStrafeInterval = 0.1;

	UFitnessUserComponent FitnessComp;
	UFitnessStrafingComponent FitnessStrafingComp;
	UBasicAICharacterMovementComponent MoveComp;
	USkylineEnforcerBoundsComponent BoundsComp;

	private float FlipCooldownDuration = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FitnessComp = UFitnessUserComponent::GetOrCreate(Owner);
		FitnessStrafingComp = UFitnessStrafingComponent::GetOrCreate(Owner);
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		BoundsComp = USkylineEnforcerBoundsComponent::GetOrCreate(Owner);

		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsActive())
			return;

		if (!TargetComp.HasValidTarget())
			return;

		if(ShouldStrafeTime == 0 || Time::GetGameTimeSince(ShouldStrafeTime) > ShouldStrafeInterval)
		{
			ShouldStrafeTime = Time::GetGameTimeSeconds();
			FVector Dest = GetStrafeDestination(DestinationComp.MinMoveDistance * 5);			
			auto FlipResult = ShouldFlip(Dest);
			bShouldStrafe = !FlipResult.bDoFlip;
			if(!bShouldStrafe)
				FitnessStrafingComp.FlipStrafeDirection();

#if EDITOR
			//Owner.bHazeEditorOnlyDebugBool = true;
			if(Owner.bHazeEditorOnlyDebugBool)
			{
				if(!bShouldStrafe)
					Debug::DrawDebugSphere(Dest, LineColor = FLinearColor::Red, Duration = 0.1);
				else
					Debug::DrawDebugSphere(Dest, LineColor = FLinearColor::Blue, Duration = 0.1);
			}
#endif
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if(!bShouldStrafe)
			return false;
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Math::Min(BasicSettings.CircleStrafeEnterRange, BasicSettings.CircleStrafeMaxRange)))
			return false;
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.CircleStrafeMinRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.CircleStrafeMaxRange))
			return true;
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.CircleStrafeMinRange))
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bTriedBothDirections = false;
		bHadVisibility = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector StrafeDest = GetStrafeDestination(DestinationComp.MinMoveDistance);
		DestinationComp.MoveTowardsIgnorePathfinding(StrafeDest, BasicSettings.CircleStrafeSpeed);

		DestinationComp.RotateTowards(TargetComp.Target);

		auto FlipResult = ShouldFlip(StrafeDest);
		if (FlipResult.bDoFlip)
		{
			if(FlipResult.Reason == EBasicFitnessCircleStrafeFlipReason::Movement || FlipResult.Reason == EBasicFitnessCircleStrafeFlipReason::Fitness)
				Cooldown.Set(Math::RandRange(1.5,3));
			else if(bTriedBothDirections)
				Cooldown.Set(2);
			FitnessStrafingComp.FlipStrafeDirection();
			bTriedBothDirections = true;
		}
	}

	private FVector GetStrafeDestination(float MinDistance)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector Side = Owner.ActorUpVector.CrossProduct(TargetLoc - OwnLoc);
		Side = Side.GetClampedToSize(MinDistance, MinDistance + 80.0);
		if (FitnessStrafingComp.bStrafeLeft)
			Side *= -1.0;
		float CircleDist = OwnLoc.Distance(TargetLoc);
		FVector CircleOffset = (OwnLoc + Side - TargetLoc).GetClampedToMaxSize(CircleDist);
		return TargetLoc + CircleOffset;
	}

	private FBasicFitnessCircleStrafeFlipResult ShouldFlip(FVector StrafeDest)
	{
		if(!BoundsComp.LocationIsWithinBounds(StrafeDest + Owner.ActorUpVector * Radius, Radius))
		{
			FBasicFitnessCircleStrafeFlipResult Result;
			Result.bDoFlip = true;
			Result.Reason = EBasicFitnessCircleStrafeFlipReason::Movement;
			return Result;
		}

		if(DestinationComp.MoveFailed())
		{
			FBasicFitnessCircleStrafeFlipResult Result;
			Result.bDoFlip = true;
			Result.Reason = EBasicFitnessCircleStrafeFlipReason::Movement;
			return Result;
		}

		bool bHasVisibility = PerceptionComp.Sight.VisibilityExists(Owner, TargetComp.Target, (StrafeDest-Owner.ActorLocation));
		if(bHadVisibility && !bHasVisibility)
		{
			FBasicFitnessCircleStrafeFlipResult Result;
			Result.bDoFlip = true;
			Result.Reason = EBasicFitnessCircleStrafeFlipReason::Visbility;
			return Result;
		}
		bHadVisibility = bHasVisibility;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(Player != nullptr && !FitnessComp.ShouldMoveToLocation(Player, StrafeDest))
		{
			FBasicFitnessCircleStrafeFlipResult Result;
			Result.bDoFlip = true;
			Result.Reason = EBasicFitnessCircleStrafeFlipReason::Fitness;
			return Result;
		}

		return FBasicFitnessCircleStrafeFlipResult();
	}
}