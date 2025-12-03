enum EFauxPhysicsAxisRotateNetworkMode
{
	// Rotation is not networked, but simulated fully locally. Impacts happen on both sides independently.
	Local,
	// Rotation is synced from the actor's control side that owns the faux physics component. Impacts are synced.
	SyncedFromActorControl,
	// Rotation is synced always from Mio's side. Impacts are synced.
	SyncedFromMioControl,
	// Rotation is synced always from Zoe's side. Impacts are synced.
	SyncedFromZoeControl,
	/**
	 * Rotation is independently calculated on both sides, and then interpolated to slowly reduce the error between them.
	 * OBS! This changes physics behavior compared to local, as the interpolation makes the physics forces a bit smaller!
	 * 	    The higher the ping, the bigger the error in the physics.
	 * OBS! Impact delegates still happen independently on both sides, and are not synced!
	 */
	TwoWaySynced,
};

event void FFauxPhysicsAxisRotateConstraintHit(float Strength);

UCLASS(ClassGroup = FauxPhysics, Meta = (HideCategories = "LOD Physics AssetUserData Collision Tags Cooking Activation Rendering"))
class UFauxPhysicsAxisRotateComponent : UFauxPhysicsComponentBase
{
	access EditAndReadOnly = private, * (editdefaults, readonly);

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	float Friction = 2.4;

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	float ForceScalar = 1.0;

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	FVector LocalRotationAxis = FVector::UpVector;

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	float SpringStrength = 0.0;

	// Bounds used for calculating torque, essentially acts as an inverse force scalar
	UPROPERTY(Category = FauxPhysics, EditAnywhere, AdvancedDisplay)
	float TorqueBounds = 100.0;

	UPROPERTY(Category = Constraints, EditAnywhere)
	bool bConstrain = false;

	UPROPERTY(Category = Constraints, EditAnywhere, Meta = (EditCondition=bConstrain))
	float ConstrainAngleMin = 0.0;

	UPROPERTY(Category = Constraints, EditAnywhere, Meta = (EditCondition=bConstrain))
	float ConstrainAngleMax = 0.0;

	UPROPERTY(Category = Constraints, EditAnywhere)
	float ConstrainBounce = 0.5;

	// Minimum strength to hit the constraint before an impact event is sent
	UPROPERTY(EditAnywhere, Category = "Impacts")
	float ImpactMinStrength = 0.5;

	// Minimum interval between impacts being registered
	UPROPERTY(EditAnywhere, Category = "Impacts")
	float MinTimeBetweenImpacts = 0.5;

	UPROPERTY(EditAnywhere, Category = "Network")
	access:EditAndReadOnly
	EFauxPhysicsAxisRotateNetworkMode NetworkMode = EFauxPhysicsAxisRotateNetworkMode::Local;

	// Important to remember that the strength given in these events is the ANGULAR VELOCITY
	//	so they will be much smaller in size than one might expect
	UPROPERTY()
	FFauxPhysicsAxisRotateConstraintHit OnMinConstraintHit;
	UPROPERTY()
	FFauxPhysicsAxisRotateConstraintHit OnMaxConstraintHit;

	UHazeCrumbSyncedFloatComponent SyncedRotation;
	UHazeTwoWaySyncedFloatComponent SyncedTwoWayRotation;

	// Networking stuff
	float SyncAngleDelta = 0.0;
	float SyncVelocityDelta = 0.0;

	// Transient values
	FQuat LocalOriginRotation;

	float Velocity;
	float CurrentRotation;

	float PendingForces;
	float PendingImpulses;

	FQuat GetWorldOriginRotation() property
	{
		if (AttachParent != nullptr)
			return AttachParent.WorldTransform.Rotation * LocalOriginRotation;
		else
			return LocalOriginRotation;
	}

	FVector GetWorldRotationAxis() property
	{
		FVector WorldAxis;
		if (World.IsGameWorld())
			WorldAxis = WorldOriginRotation * LocalRotationAxis;
		else
			WorldAxis = WorldTransform.TransformVectorNoScale(LocalRotationAxis);

		return WorldAxis.SafeNormal;
	}

	FQuat GetCurrentRotationAsQuat() property
	{
		return FQuat(WorldRotationAxis, CurrentRotation);
	}

	// Force applications
	void ApplyForce(FVector Origin, FVector Force) override
	{
		if (!IsEnabled())
			return;

		PendingForces += ConvertToAngularDelta(Origin, Force) * ForceScalar;
		Wake();
	}

	void ApplyImpulse(FVector Origin, FVector Force) override
	{
		if (!IsEnabled())
			return;

		PendingImpulses += ConvertToAngularDelta(Origin, Force) * ForceScalar;
		Wake();
	}

	void ApplyAngularForce(float AngularForceRadians)
	{
		if (!IsEnabled())
			return;

		PendingForces += AngularForceRadians * ForceScalar;
		Wake();
	}

	void ApplyAngularImpulse(float AngularImpulseRadians)
	{
		if (!IsEnabled())
			return;

		PendingImpulses += AngularImpulseRadians * ForceScalar;
		Wake();
	}

	void ApplyAngularMovement(float AngleRadians)
	{
		if (!IsEnabled())
			return;

		CurrentRotation += AngleRadians;
		
		if (bConstrain)
			ApplyConstraints();

		// Apply rotation
		if(HasFauxPhysicsControl())
			ControlUpdateSyncedPosition();

		Wake();
	}

	void ApplyMovement(FVector Origin, FVector Movement) override
	{
		if (!IsEnabled())
			return;

		CurrentRotation += ConvertToAngularDelta(Origin, Movement);
		if (bConstrain)
			ApplyConstraints();

		// Apply rotation
		if(HasFauxPhysicsControl())
			ControlUpdateSyncedPosition();

		Wake();
	}

	/**
	 * Map the current position to alpha values between 0 and 1,
	 * where 0 indicates the minimum angle constraint, and 1 indicates the maximum angle constraint.
	 * 
	 * NB. If the rotation is unconstrained, returns 0 for no rotation and 1 for 360 degrees of rotation.
	 */

	UFUNCTION(BlueprintPure)
	float GetCurrentAlphaBetweenConstraints() const
	{
		if (bConstrain)
		{
			if (ConstrainAngleMin != ConstrainAngleMax)
			{
				float MinRadians = Math::DegreesToRadians(ConstrainAngleMin);
				float MaxRadians = Math::DegreesToRadians(ConstrainAngleMax);
				return (CurrentRotation - MinRadians) / (MaxRadians - MinRadians);
			}
			else
			{
				return 0.0;
			}
		}
		else
		{
			float NormalizedRotation = Math::Wrap(CurrentRotation, 0.0, TWO_PI);
			return NormalizedRotation / TWO_PI;
		}
	}

	private float ConvertToAngularDelta(FVector Origin, FVector Delta)
	{
		FVector RotationAxis = GetWorldRotationAxis();

		FVector BoundedDelta = Delta.ConstrainToPlane(RotationAxis);
		FVector BoundedOffset = (Origin - WorldLocation).ConstrainToPlane(RotationAxis);

		float OffsetSize = BoundedOffset.Size();
		if (OffsetSize < 0.01)
			return 0.0;

		FVector OffsetDirection = BoundedOffset / OffsetSize;
		if (OffsetDirection.DotProduct(RotationAxis) >= 1.0)
			return 0.0;

		FVector MovementAxis = RotationAxis.CrossProduct(OffsetDirection);
		//Debug::DrawDebugLine(Origin, Origin + MovementAxis * 50.0, FLinearColor::Red, 10.0, 2.0);
		//Debug::DrawDebugLine(WorldLocation + BoundedOffset, WorldLocation + BoundedOffset + MovementAxis * 100.0, FLinearColor::Red, 10.0, 2.0);
		//Debug::DrawDebugLine(WorldLocation + BoundedOffset, WorldLocation + BoundedOffset + Delta.GetSafeNormal() * 100.0, FLinearColor::Blue, 10.0, 2.0);

		float OffsetBoundsAlpha = OffsetSize / TorqueBounds;
		float UnitMovement = MovementAxis.DotProduct(BoundedDelta) * OffsetBoundsAlpha;

		float AngularMovement = UnitMovement / OffsetSize;
		return AngularMovement;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (NetworkMode != EFauxPhysicsAxisRotateNetworkMode::Local && Network::IsGameNetworked())
		{
			if (NetworkMode != EFauxPhysicsAxisRotateNetworkMode::TwoWaySynced)
			{
				SyncedRotation = UHazeCrumbSyncedFloatComponent::Create(Owner, FName(GetName() + "_Rotation"));
				switch (NetworkMode)
				{
					case EFauxPhysicsAxisRotateNetworkMode::SyncedFromMioControl:
						SyncedRotation.OverrideControlSide(Game::Mio);
					break;
					case EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl:
						SyncedRotation.OverrideControlSide(Game::Zoe);
					break;
					default:
					break;
				}
				SyncedRotation.OnWake.AddUFunction(this, n"OnSyncWake");
			}
			else
			{
				SyncedTwoWayRotation = UHazeTwoWaySyncedFloatComponent::Create(Owner, FName(GetName() + "_Rotation"));
				SyncedTwoWayRotation.OnWake.AddUFunction(this, n"OnSyncWake");
			}

			devCheck(MinTimeBetweenImpacts >= 0.1, f"FauxPhysics component {this} on {Owner} is networked but MinTimeBetweenImpacts is set to {MinTimeBetweenImpacts}, increase minimum time to prevent network spam.");
		}

		// Make sure the constrain angles are in the correct order
		if (ConstrainAngleMin > ConstrainAngleMax)
		{
			float Temp = ConstrainAngleMin;
			ConstrainAngleMin = ConstrainAngleMax;
			ConstrainAngleMax = Temp;
		}

		LocalOriginRotation = RelativeTransform.Rotation;
	}

	void OverrideNetworkSyncRate(EHazeCrumbSyncRate SyncRate) override
	{
		if (SyncedRotation != nullptr)
			SyncedRotation.OverrideSyncRate(SyncRate);
		if (SyncedTwoWayRotation != nullptr)
			SyncedTwoWayRotation.OverrideSyncRate(SyncRate);
	}

	bool HasFauxPhysicsControl() const override
	{
		if (SyncedRotation != nullptr)
			return SyncedRotation.HasControl();
		return true;
	}

	void ResetForces() override
	{
		PendingForces = 0.0;
	}

	void ResetPhysics() override
	{
		Velocity = 0.0;
	}

	void ResetInternalState() override
	{
		Super::ResetInternalState();
		
		CurrentRotation = 0.0;
	}

	void ApplyConstraints()
	{
		float MinRadians = Math::DegreesToRadians(ConstrainAngleMin);
		float MaxRadians = Math::DegreesToRadians(ConstrainAngleMax);

		if (CurrentRotation < MinRadians)
		{
			TriggerImpact(true, Math::Abs(Velocity));

			CurrentRotation = MinRadians;
			if (Velocity < 0.0)
				Velocity -= Velocity * (1.0 + ConstrainBounce);
		}
		if (CurrentRotation > MaxRadians)
		{
			TriggerImpact(false, Math::Abs(Velocity));

			CurrentRotation = MaxRadians;
			if (Velocity > 0.0)
				Velocity -= Velocity * (1.0 + ConstrainBounce);
		}
	}

	bool UpdateFauxPhysics(float InOriginalDeltaTime) override
	{
		if (SyncedTwoWayRotation != nullptr)
			CurrentRotation = SyncedTwoWayRotation.Value;

		return Super::UpdateFauxPhysics(InOriginalDeltaTime);
	}

	UFUNCTION()
	private void OnSyncWake()
	{
		Wake();
	}

	bool CanSleep() const override
	{
		// Don't sleep while still syncing
		if (HasFauxPhysicsControl())
		{
			// Don't sleep if we can still spring back
			if (SpringStrength > SMALL_NUMBER && !Math::IsNearlyZero(CurrentRotation))
				return false;

			// Don't sleep while moving
			if (!Math::IsNearlyZero(PendingForces))
				return false;
			if (!Math::IsNearlyZero(PendingImpulses))
				return false;
			if (!Math::IsNearlyZero(Velocity))
				return false;

			if (SyncedTwoWayRotation != nullptr)
			{
				if (!SyncedTwoWayRotation.IsSleeping())
					return false;
			}
		}
		else
		{
			if (!SyncedRotation.IsSleeping())
				return false;
			if (!Math::IsNearlyEqual(SyncedRotation.Value, CurrentRotation))
				return false;
		}

		return true;
	}

	protected void PhysicsStep(float DeltaTime) override
	{
		// Spring force
		bool bZeroRotation = Math::Abs(CurrentRotation) < 0.001;
		if (SpringStrength > SMALL_NUMBER)
		{
			if (!bZeroRotation)
				Velocity -= CurrentRotation * SpringStrength * DeltaTime;
			else if (Math::Abs(Velocity) < 0.01)
				CurrentRotation = 0.0;
		}

		Velocity += PendingForces * DeltaTime;
		Velocity += PendingImpulses;
		Velocity = FauxPhysics::Calculation::ApplyFriction(Velocity, Friction, DeltaTime);

		// Clear impulses right away, so we dont impulse on every substep
		PendingImpulses = 0.0;

		// Move!
		CurrentRotation += Velocity * DeltaTime;

		// Apply constraints
		if (bConstrain)
			ApplyConstraints();
	}

	protected void ControlUpdateSyncedPosition() override
	{
		check(HasFauxPhysicsControl());

		FQuat FinalRotation = CurrentRotationAsQuat * WorldOriginRotation;
		SetWorldRotation(FinalRotation);

		if (SyncedRotation != nullptr)
			SyncedRotation.Value = CurrentRotation;
		else if (SyncedTwoWayRotation != nullptr)
			SyncedTwoWayRotation.Value = CurrentRotation;
	}

	protected void RemoteUpdateSyncedPosition() override
	{
		if (SyncedRotation == nullptr)
			return;

		check(!HasFauxPhysicsControl());

		CurrentRotation = SyncedRotation.Value;

		FQuat FinalRotation = CurrentRotationAsQuat * WorldOriginRotation;
		SetWorldRotation(FinalRotation);

		// Trigger impacts the control side sent to us
		float TrailTime = SyncedRotation.GetCrumbTrailReceiveTime();
		for (int i = QueuedImpacts.Num() - 1; i >= 0; --i)
		{
			// Impact hasn't been reached yet
			auto& QueuedImpact = QueuedImpacts[i];
			if (QueuedImpact.CrumbTrailTime > TrailTime)
				continue;

			// Apply the impact
			if (QueuedImpact.bMinImpact)
				OnMinConstraintHit.Broadcast(QueuedImpact.Strength);
			else
				OnMaxConstraintHit.Broadcast(QueuedImpact.Strength);
			QueuedImpacts.RemoveAtSwap(i);
		}
	}

	private TArray<FFauxPhysicsAxisRotateImpact> QueuedImpacts;
	private float IgnoreImpactsUntil = 0.0;

	private void TriggerImpact(bool bMinImpact, float Strength)
	{
		if (Strength < ImpactMinStrength)
			return;
		if (Time::GameTimeSeconds < IgnoreImpactsUntil)
			return;

		IgnoreImpactsUntil = Time::GameTimeSeconds + MinTimeBetweenImpacts;

		if (bMinImpact)
			OnMinConstraintHit.Broadcast(Strength);
		else
			OnMaxConstraintHit.Broadcast(Strength);

		if (SyncedRotation != nullptr && HasFauxPhysicsControl() && FauxPhysics::Calculation::CVar_DropAllRemoteImpacts.GetInt() == 0)
		{
			if (bMinImpact ? OnMinConstraintHit.IsBound() : OnMaxConstraintHit.IsBound())
			{
				NetSendImpact(
					SyncedRotation.GetCrumbTrailSendTime(),
					bMinImpact,
					Strength
				);
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetSendImpact(float CrumbTrailTime, bool bMinImpact, float Strength)
	{
		if (HasFauxPhysicsControl())
			return;

		FFauxPhysicsAxisRotateImpact Impact;
		Impact.CrumbTrailTime = CrumbTrailTime;
		Impact.bMinImpact = bMinImpact;
		Impact.Strength = Strength;
		QueuedImpacts.Add(Impact);
	}
}

struct FFauxPhysicsAxisRotateImpact
{
	float CrumbTrailTime;
	float Strength;
	bool bMinImpact;
}

class UFauxPhysicsAxisRotateComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UFauxPhysicsAxisRotateComponent;
	const float Radius = 250.0;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		if(!Editor::IsComponentSelected(Component) && !Component.World.IsPreviewWorld())
			return;

		auto RotateComponent = Cast<UFauxPhysicsAxisRotateComponent>(Component);

		FVector WorldAxis = RotateComponent.WorldRotationAxis;

		// Perpendicular is sort of like the "forward" of the rotation, IE the direction when 0 rotation is applied
		// It is sort of arbitrary
		FVector WorldPerpendicular = RotateComponent.WorldOriginRotation * FVector::ForwardVector;

		// Oops, seems like our perpendicular is the same as the axis, not allowed. Pick another one
		if (WorldAxis.Equals(WorldPerpendicular))
			WorldPerpendicular = RotateComponent.WorldOriginRotation * FVector::UpVector;

		// Then, when an arbitrary vector is chosen, flatten it out to the rotation axis
		WorldPerpendicular = WorldPerpendicular.ConstrainToPlane(WorldAxis).SafeNormal;

		FVector CurrentPerpendicular = RotateComponent.CurrentRotationAsQuat * WorldPerpendicular;

		// Draw rotation axis
		DrawArrow(RotateComponent.WorldLocation, RotateComponent.WorldLocation + WorldAxis * Radius, FLinearColor::Blue, 15.0, 5.0);

		// Draw the rotation plane
		if (RotateComponent.bConstrain)
			DrawClampedRotationAxis(RotateComponent.WorldLocation, WorldAxis, WorldPerpendicular, RotateComponent.ConstrainAngleMin, RotateComponent.ConstrainAngleMax, FLinearColor::Blue);
		else
			DrawUnclampedRotationAxis(RotateComponent.WorldLocation, WorldAxis, WorldPerpendicular, FLinearColor::Yellow);

		DrawAxisLine(RotateComponent.WorldLocation, CurrentPerpendicular, FLinearColor::Red);

		// If we've customized the torque bounds, show them
		if (RotateComponent.TorqueBounds != 100.0)
		{
			DrawWireSphere(
				RotateComponent.WorldLocation,
				RotateComponent.TorqueBounds,
				FLinearColor(1.0, 0.5, 0.0),
				0.5);
		}
	}

	void DrawClampedRotationAxis(FVector Location, FVector Axis, FVector Perpendicular, float MinAngle, float MaxAngle, FLinearColor Color)
	{
		DrawHalfClampedRotationAxis(Location, Axis, Perpendicular, Radius, MaxAngle, Color);
		DrawHalfClampedRotationAxis(Location, Axis, Perpendicular, Radius, MinAngle, Color * 0.4);
	}

	void DrawHalfClampedRotationAxis(FVector Location, FVector Axis, FVector Perpendicular, float RotationRadius, float Angle, FLinearColor Color)
	{
		bool bIsCapped = Angle < 350.0;
		float CappedAngle = Math::Min(Angle, 350.0);

		// Since we're drawing a centered arc, we need to start the arc at the middle
		FVector MiddlePoint = FQuat(Axis, Math::DegreesToRadians(Angle / 2.0)) * Perpendicular;
		DrawArc(Location, CappedAngle, RotationRadius, MiddlePoint, Color, 5.0, Normal = Axis, Segments = 32, bDrawSides = false);

		// Arrows to show uncapped rotation
		FQuat CapQuat = FQuat(Axis, Math::DegreesToRadians(CappedAngle));

		if (bIsCapped)
		{
			FVector CapDirection = CapQuat * Perpendicular;
			DrawLine(Location + CapDirection * (RotationRadius - 50.0), Location + CapDirection * (RotationRadius + 50.0), Color, 5.0);
		}
		else
		{
			FQuat CapEndQuat = FQuat(Axis, Math::DegreesToRadians(CappedAngle + 5.0 * Math::Sign(CappedAngle)));
			FVector CapStartLocation = Location + (CapQuat * Perpendicular) * RotationRadius;
			FVector CapEndLocation = Location + (CapEndQuat * Perpendicular) * RotationRadius;

			DrawArrow(CapStartLocation, CapEndLocation, Color, 25.0, 5.0);
		}
	}

	void DrawUnclampedRotationAxis(FVector Location, FVector Axis, FVector Perpendicular, FLinearColor Color)
	{
		// Again, want an arc from the perpendicular to the perpendicular + 340 degrees
		// And since arcs are drawn from the middle....
		FVector MiddlePoint = FQuat(Axis, Math::DegreesToRadians(340.0 / 2.0)) * Perpendicular;
		DrawArc(Location, 340.0, Radius, MiddlePoint, Color, 5.0, Normal = Axis, Segments = 32, bDrawSides = false);

		FQuat CapStartQuat = FQuat(Axis, Math::DegreesToRadians(340.0));
		FQuat CapEndQuat = FQuat(Axis, Math::DegreesToRadians(345.0));

		FVector CapStartLocation = Location + (CapStartQuat * Perpendicular) * Radius;
		FVector CapEndLocation = Location + (CapEndQuat * Perpendicular) * Radius;
		DrawArrow(CapStartLocation, CapEndLocation, Color, 25.0, 5.0);
	}

	void DrawAxisLine(FVector Origin, FVector Direction, FLinearColor Color)
	{
		FVector Tip = Direction * Radius;

		DrawLine(Origin, Origin + Tip, Color, 3.0);
		DrawWireSphere(Origin + Tip, 5.0, Color);
	}
}