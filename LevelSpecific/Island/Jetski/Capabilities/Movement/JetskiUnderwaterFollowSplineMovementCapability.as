/**
 * A special underwater mode that locks the player to a spline, basically forcing a continuous dive
 */
class UJetskiUnderwaterFollowSplineMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 50;

	AJetski Jetski;
	UJetskiMovementComponent MoveComp;
	UJetskiMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
		MoveComp = Jetski.MoveComp;
		MoveData = MoveComp.SetupJetskiMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!Jetski.IsInWater())
			return false;

		if(!ShouldEnterUnderwaterFollowSplineMode())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!ShouldEnterUnderwaterFollowSplineMode())
		{
			if(!Jetski.IsInWater())
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Jetski.SetMovementState(EJetskiMovementState::Underwater);
		Jetski.bIsJumpingFromUnderwater = false;

		Jetski.ApplySettings(JetskiUnderwaterSettings, this);
		Jetski.ApplySettings(JetskiUnderwaterMovementSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bool bClampedVelocity = false;
		FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
		FVector VerticalVelocity = MoveComp.VerticalVelocity;

		if(VerticalVelocity.Z > MoveComp.MovementSettings.UnderwaterFollowSplineMaxJumpSpeed)
		{
			VerticalVelocity.Z = MoveComp.MovementSettings.UnderwaterFollowSplineMaxJumpSpeed;
			bClampedVelocity = true;
		}

		if(HorizontalVelocity.Size() > MoveComp.MovementSettings.UnderwaterFollowSplineMaxJumpHorizontalSpeed)
		{
			HorizontalVelocity = HorizontalVelocity.GetClampedToMaxSize(MoveComp.MovementSettings.UnderwaterFollowSplineMaxJumpHorizontalSpeed);
			bClampedVelocity = true;
		}

		if(bClampedVelocity)
		{
			FVector Velocity = HorizontalVelocity + VerticalVelocity;
			Jetski.SetActorVelocity(Velocity);
		}

		Jetski.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const UHazeSplineComponent Spline = Jetski.GetActiveSplineComponent();
		const float SplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(Jetski.ActorLocation);
		const FTransform SplineTransform = Spline.GetWorldTransformAtSplineDistance(SplineDistance);
		const FVector UpVector = Spline.GetWorldRotationAtSplineDistance(SplineDistance).UpVector;

		if (!MoveComp.PrepareMove(MoveData, Jetski.ActorUpVector))
			return;

		if (HasControl())
		{
			Jetski.AccelerateUpTowards(FQuat::MakeFromZX(UpVector, Jetski.ActorForwardVector), 1, DeltaTime, this);
			
			const float InitialForwardSpeed = Jetski.GetForwardSpeed(EJetskiUp::Spline);
			const float HorizontalSpeed = Jetski.GetAcceleratedSpeed(InitialForwardSpeed, DeltaTime);

			const FVector HorizontalVelocity = Jetski.GetHorizontalForward(EJetskiUp::Spline) * HorizontalSpeed;
			MoveData.AddVelocity(HorizontalVelocity);

			const FVector RelativeLocation = SplineTransform.InverseTransformPositionNoScale(Jetski.ActorLocation);
			float VerticalSpeed = Jetski.MoveComp.Velocity.DotProduct(UpVector);
			FHazeAcceleratedFloat AccVerticalOffset;
			AccVerticalOffset.SnapTo(RelativeLocation.Z, VerticalSpeed);
			AccVerticalOffset.AccelerateTo(0, 2, DeltaTime);

			const float Delta = AccVerticalOffset.Value - RelativeLocation.Z;
			MoveData.AddDelta(SplineTransform.TransformVectorNoScale(FVector(0, 0, Delta)));

			Jetski.SteerJetski(MoveData, DeltaTime);
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	bool ShouldEnterUnderwaterFollowSplineMode() const
	{
		TOptional<FAlongSplineComponentData> PreviousUnderaterZone = Jetski.GetActiveSplineComponent().FindPreviousComponentAlongSpline(UJetskiSplineUnderwaterZoneComponent, true, Jetski.GetDistanceAlongSpline());
		if(!PreviousUnderaterZone.IsSet())
			return false;

		return Cast<UJetskiSplineUnderwaterZoneComponent>(PreviousUnderaterZone.Value.Component).bForceUnderwater;
	}
};