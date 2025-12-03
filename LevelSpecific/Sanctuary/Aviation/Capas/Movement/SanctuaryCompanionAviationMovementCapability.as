class USanctuaryCompanionAviationMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default DebugCategory = AviationCapabilityTags::Aviation;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	UPlayerMovementComponent MoveComp;
    USimpleMovementData Movement;

	FVector Direction;
	FVector SafeDirection;
	FVector InitialTowardsDestination;
	FVector InitialRightOfDestination;
	FVector SplineDirection;

	FHazeAcceleratedVector AccBarrelRollUp;
	FHazeAcceleratedVector AccForwardDirection;
	FHazeAcceleratedFloat AccSpeed;
	float EntrySpeedAlpha = 0.0;
	float OriginalDistance;
	FSanctuaryCompanionAviationDestinationSplineData DestinationSplineData;

	bool bDebug = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!AviationComp.GetIsAviationActive())
			return false;

		if (!AviationComp.HasDestination())
			return false;

		if (IsInUnhandledState())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!AviationComp.GetIsAviationActive())
			return true;

		if (!AviationComp.HasDestination())
			return true;

		if (IsInUnhandledState())
			return true;

		return false;
	}

	bool IsInUnhandledState() const
	{
		if (AviationComp.GetAviationState() == EAviationState::ToAttack)
			return true;
		if (AviationComp.GetAviationState() == EAviationState::InitAttack)
			return true;
		if (AviationComp.GetAviationState() == EAviationState::Attacking)
			return true;
		if (AviationComp.GetAviationState() == EAviationState::TryExitAttack)
			return true;
		if (AviationComp.GetAviationState() == EAviationState::AttackingSuccessCircling)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BlockedWhileIn::AirMotion, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);
        if (!HasControl())
            return;

		Direction = Owner.ActorForwardVector;
		InitialTowardsDestination = GetToTarget().GetSafeNormal();

		if (!AviationComp.bAviationStartSnappedDirection)
		{
			Direction = InitialTowardsDestination;
			AviationComp.bAviationStartSnappedDirection = true;
		}
		SafeDirection = Direction;
		AccForwardDirection.SnapTo(SafeDirection);

		InitialRightOfDestination = FVector::UpVector.CrossProduct(InitialTowardsDestination).GetSafeNormal();
		AccBarrelRollUp.SnapTo(Player.ActorUpVector);
		AccSpeed.SnapTo(GetCurrentSpeed());
		EntrySpeedAlpha = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BlockedWhileIn::AirMotion, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		if (!HasControl())
            return;
		AviationComp.ResetEndOfMovementSpline();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				bDebug = AviationDevToggles::DrawPath.IsEnabled();
				FVector SafeBlendedDirection = GetBlendedSafeDirection(DeltaTime);
				AccForwardDirection.AccelerateTo(SafeBlendedDirection, GetAccelerationDuration(), DeltaTime);
				FVector NewForwardVelocity = AccForwardDirection.Value;

				if (MoveComp.Velocity.Size() > KINDA_SMALL_NUMBER) // Take old velocity into account as well
					NewForwardVelocity = NewForwardVelocity * MoveComp.Velocity.Size() + MoveComp.Velocity;

				AccSpeed.AccelerateTo(GetCurrentSpeed(), 0.2, DeltaTime);
				NewForwardVelocity = NewForwardVelocity.GetClampedToSize(AccSpeed.Value - 1.0, AccSpeed.Value);
                // Movement.AddVelocity(NewForwardVelocity);
                Movement.AddDelta(NewForwardVelocity * DeltaTime);

				// Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + NewForwardVelocity, FLinearColor::LucBlue, 5.0, 0.0, true);
				Movement.SetRotation(GetNewRotation(NewForwardVelocity.GetSafeNormal(), DeltaTime));
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
		}
	}

	// -------------------

	private FVector GetToTarget()
	{
		FSanctuaryCompanionAviationDestinationData DestinationData = AviationComp.GetNextDestination();
		FVector ToTarget;
		AviationComp.ResetEndOfMovementSpline();
		SplineDirection = FVector::ZeroVector;
		if (DestinationData.HasRuntimeSpline())
		{
			if (bDebug)
				DestinationData.RuntimeSpline.DrawDebugSpline();

			DestinationData.GetSplineData(Player.ActorLocation, 500.0 , DestinationSplineData);
			if (DestinationSplineData.bIsAtEnd || AviationComp.bControlIsAtEndOfMovementSpline)
				AviationComp.SetEndOfMovementSpline(); 
			
			ToTarget = DestinationSplineData.NextSplineLocation - Owner.ActorLocation;
			if (bDebug)
				Debug::DrawDebugLine(Player.ActorLocation, DestinationSplineData.NextSplineLocation, FLinearColor::LucBlue, 10.0, 0.0, true);

			if (AviationComp.AviationState == EAviationState::Entry)
			{
				EntrySpeedAlpha = DestinationSplineData.TraversedPercent;
				// PrintToScreen("% " + EntrySpeedAlpha);
			}
		}
		else if (DestinationData.IsTargetingBone())
		{
			// special case to aim towards to the right of a hydra head, to initiate the glory kill attack
			FVector BoneLocation = DestinationData.GetLocation();// + InitialRightOfDestination * CompanionAviation::StranglingMaxRadius * AviationComp.GetLeftRightOctantMultiplier();
			// Debug::DrawDebugLine(Player.ActorLocation, BoneLocation, FLinearColor::Red, 10.0, 0.0, true);
			ToTarget = (BoneLocation - Owner.ActorLocation);
			if (bDebug)
				Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToTarget, FLinearColor::Red, 5.0, 0.0, true);
		}
		else if (DestinationData.Actor != nullptr)
		{
			ToTarget = (DestinationData.Actor.ActorLocation - Owner.ActorLocation);
		}

		return ToTarget;
	}

	private float GetCurrentSpeed()
	{
		if (AviationComp.AviationState == EAviationState::SwoopingBack)
			return AviationComp.Settings.SwoopbackSpeed;
		if (AviationComp.AviationState == EAviationState::Entry)
			return Math::Lerp(AviationComp.Settings.EntrySpeed, AviationComp.Settings.SidewaysForwardSpeed, EntrySpeedAlpha);
		return AviationComp.Settings.ExitSpeed;
	}

	private FRotator GetNewRotation(FVector ForwardDirection, float DeltaTime)
	{
		FVector RightLeft = Player.ActorRightVector * Player.ActorRightVector.DotProduct(ForwardDirection);
		// Debug::DrawDebugString(Player.ActorLocation, "Right: " + RightLeft.Y);
		RightLeft.Z = 1.0;
		AccBarrelRollUp.AccelerateTo(RightLeft, 1.0, DeltaTime);
		return FRotator::MakeFromXZ(ForwardDirection, AccBarrelRollUp.Value.GetSafeNormal());
	}

	private FVector GetBlendedSafeDirection(float DeltaTime)
	{
		FVector ToTarget = GetToTarget();

		FVector TargetDirection = ToTarget.GetSafeNormal();
		if (TargetDirection.Size() < KINDA_SMALL_NUMBER * 2.0)
			TargetDirection = SafeDirection;

		Direction = Math::VInterpNormalRotationTo(Direction, TargetDirection.GetSafeNormal(), DeltaTime, AviationComp.Settings.NormalAviationInterpolateDirectionSpeed);

		//Get last direction before input reaches almost 0
		if (Direction.Size() > KINDA_SMALL_NUMBER * 2.0)
			SafeDirection = Direction.GetSafeNormal();

		return SafeDirection;
	}

	private float GetAccelerationDuration()
	{
		return AviationComp.Settings.NormalAviationInterpolateDirectionDuration;
	}
}

