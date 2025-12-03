enum EFauxPhysicsSplineTranslateConstraintEdge
{
	Spline,
	AxisZ_Min,
	AxisZ_Max,
};

enum EFauxPhysicsSplineTranslateShape
{
	Point,
	Cylinder,
	Box,
};

event void FFauxPhysicsSplineTranslateConstraintHit(FSplinePosition SplinePosition, EFauxPhysicsSplineTranslateConstraintEdge Edge, float HitStrength);

/**
 * The same as FauxPhysicsTranslateComponent, but constrained by splines and height instead of XYZ location.
 */
UCLASS(ClassGroup = FauxPhysics, Meta = (HideCategories = "LOD Physics AssetUserData Collision Tags Cooking Activation Rendering"))
class UFauxPhysicsSplineTranslateComponent : UFauxPhysicsComponentBase
{
	access EditAndReadOnly = private, * (editdefaults, readonly);

	private FVector Velocity;
	private FVector PendingForces;
	private FVector PendingImpulses;

	UPROPERTY(Category = "FauxPhysics", EditAnywhere)
	float Friction = 2.4;

	UPROPERTY(Category = "FauxPhysics", EditAnywhere)
	float ForceScalar = 1.0;

	UPROPERTY(Category = "Constraints|Spline", EditAnywhere)
	bool bConstrainWithSpline = true;

	int Iteration = 0;

	UPROPERTY(EditInstanceOnly, Category = "Constraints|Spline", Meta = (EditCondition = "bConstrainWithSpline"))
	ASplineActor OtherSplineActor;

	/**
	 * If the inside is on the right side of the spline, we are clockwise.
	 * If left, counter clockwise.
	 * This is required since we never ever want to end up outside of the spline!
	 * At the moment, this has to be manually defined because I am smooth brained.
	 */
	UPROPERTY(EditInstanceOnly, Category = "Constraints|Spline", Meta = (EditCondition = "bConstrainWithSpline", EditConditionHides))
	bool bClockwise = true;

	UPROPERTY(EditAnywhere, Category = "Constraints|Shape", Meta = (EditCondition = "bConstrainWithSpline", EditConditionHides))
	EFauxPhysicsSplineTranslateShape Shape = EFauxPhysicsSplineTranslateShape::Point;

	UPROPERTY(EditAnywhere, Category = "Constraints|Shape", Meta = (EditCondition = "bConstrainWithSpline && Shape == EFauxPhysicsSplineTranslateShape::Cylinder", EditConditionHides, ClampMin = "0.0"))
	float Radius = 100;

	UPROPERTY(EditAnywhere, Category = "Constraints|Shape", Meta = (EditCondition = "bConstrainWithSpline && Shape == EFauxPhysicsSplineTranslateShape::Cylinder", EditConditionHides))
	float HalfHeight = 100;

	UPROPERTY(EditAnywhere, Category = "Constraints|Shape", Meta = (EditCondition = "bConstrainWithSpline && Shape == EFauxPhysicsSplineTranslateShape::Box", EditConditionHides))
	FVector Extents = FVector(100);

	/**
	 * Spline component on this actor that should be constraining this component.
	 */
	UPROPERTY(EditInstanceOnly, Category = "Constraints|Spline", Meta = (EditCondition = "bConstrainWithSpline && OtherSplineActor == nullptr", UseComponentPicker, AllowedClasses = "/Script/Angelscript.HazeSplineComponent"))
	FComponentReference SplineComponentOnThisActor;

	UPROPERTY(Category = "Constraints|Z", EditAnywhere)
	bool bConstrainZ = false;

	UPROPERTY(Category = "Constraints|Z", EditAnywhere, Meta = (EditCondition = "bConstrainZ", EditConditionHides))
	float MinZ = 0.0;

	UPROPERTY(Category = "Constraints|Z", EditAnywhere, Meta = (EditCondition = "bConstrainZ", EditConditionHides))
	float MaxZ = 0.0;

	UPROPERTY(Category = "Constraints", EditAnywhere)
	float ConstrainBounce = 0.5;

	UPROPERTY(Category = "Spring", EditAnywhere)
	float SpringStrength = 0.0;

	UPROPERTY(Category = "Constraints|Z", EditAnywhere)
	float ConstrainedVerticalVelocity = 0.0;
	UPROPERTY(Category = "Constraints", EditAnywhere)
	float ConstrainedHorizontalVelocity = 0.0;

	UPROPERTY()
	FFauxPhysicsSplineTranslateConstraintHit OnConstraintHit;

	// Minimum strength to hit the constraint before an impact event is sent
	UPROPERTY(EditAnywhere, Category = "Impacts")
	float ImpactMinStrength = 50.0;

	// Minimum interval between impacts being registered
	UPROPERTY(EditAnywhere, Category = "Impacts")
	float MinTimeBetweenImpacts = 0.5;

	UPROPERTY(EditAnywhere, Category = "Network")
	access:EditAndReadOnly
	EFauxPhysicsTranslateNetworkMode NetworkMode = EFauxPhysicsTranslateNetworkMode::Local;

	FVector SpringParentOffset;

	private FVector CurrentPhysicsLocation;

	private UHazeSplineComponent Spline;

	private UHazeCrumbSyncedVectorComponent SyncedLocation; 
	private UHazeTwoWaySyncedVectorComponent SyncedTwoWayLocation;

	void Swap(float& A, float& B)
	{
		float Temp = A;
		B = A;
		A = Temp;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		// In case min and max are flipped, make them not-flipped
		if (MinZ > MaxZ)
			Swap(MinZ, MaxZ);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		SpringParentOffset = GetRelativeLocation();
		CurrentPhysicsLocation = GetWorldLocation();

		//Extents3D = FVector(Extents.X, Extents.Y, 0);

		if(bConstrainWithSpline)
		{
			Spline = FindSplineComponentToUse();
			if(!ValidateSpline(Spline))
				bConstrainWithSpline = false;
		}

		if (NetworkMode != EFauxPhysicsTranslateNetworkMode::Local && Network::IsGameNetworked())
		{
			if (NetworkMode != EFauxPhysicsTranslateNetworkMode::TwoWaySynced)
			{
				SyncedLocation = UHazeCrumbSyncedVectorComponent::Create(Owner, FName(GetName() + "_Location"));
				switch (NetworkMode)
				{
					case EFauxPhysicsTranslateNetworkMode::SyncedFromMioControl:
						SyncedLocation.OverrideControlSide(Game::Mio);
					break;
					case EFauxPhysicsTranslateNetworkMode::SyncedFromZoeControl:
						SyncedLocation.OverrideControlSide(Game::Zoe);
					break;
					default:
					break;
				}
				SyncedLocation.OnWake.AddUFunction(this, n"OnSyncWake");
			}
			else
			{
				SyncedTwoWayLocation = UHazeTwoWaySyncedVectorComponent::Create(Owner, FName(GetName() + "_Location"));
				SyncedTwoWayLocation.OnWake.AddUFunction(this, n"OnSyncWake");
			}

			devCheck(MinTimeBetweenImpacts >= 0.1, f"FauxPhysics component {this} on {Owner} is networked but MinTimeBetweenImpacts is set to {MinTimeBetweenImpacts}, increase minimum time to prevent network spam.");
		}

		if (SyncedLocation != nullptr)
			SyncedLocation.Value = GetRelativeLocation();
	}

	UHazeSplineComponent FindSplineComponentToUse() const
	{
		if(OtherSplineActor != nullptr)
			return OtherSplineActor.Spline;

		if(SplineComponentOnThisActor.ComponentProperty != NAME_None)
		{
			return Cast<UHazeSplineComponent>(SplineComponentOnThisActor.GetComponent(Owner));
		}

		return nullptr;
	}

	private bool ValidateSpline(UHazeSplineComponent SplineComp) const
	{
		if(SplineComp == nullptr)
		{
			PrintError(f"FauxPhysicsSplineTranslateComponent {Name} attached to {Owner.Name} has bConstrainWithSplines turned on, but found no spline to use!");
			return false;
		}

		// Only allow closed loop splines
		if(!ensure(Spline.IsClosedLoop()))
		{
			PrintError(f"FauxPhysicsSplineTranslateComponent {Name} attached to {Owner.Name} has bConstrainWithSplines turned on, but the spline is not looping!");
			return false;
		}

#if EDITOR
			// Validate that we aren't trying to use a Spline that is attached to this component
			USceneComponent TestComp = SplineComp;
			while(TestComp.AttachParent != nullptr)
			{
				if(TestComp.AttachParent == this)
				{
					PrintError(f"FauxPhysicsSplineTranslateComponent {Name} attached to {Owner.GetActorNameOrLabel()} has a SplineComponent assigned that is attached to the FauxPhysicsSplineTranslateComponent. This is not allowed!");
					return false;
				}

				TestComp = TestComp.AttachParent;
			}
#endif

		// FB TODO: Can we figure out clockwise/counter clockwise instead of having the user set it?
		// FB TODO: Validate that we are currently inside the spline loop

		return true;
	}

	void SetSpline(UHazeSplineComponent SplineComp)
	{
		if(ValidateSpline(SplineComp))
		{
			bConstrainWithSpline = true;
			Spline = SplineComp;
		}
		else
		{
			bConstrainWithSpline = false;
		}
	}

	void OverrideNetworkSyncRate(EHazeCrumbSyncRate SyncRate) override
	{
		if (SyncedLocation != nullptr)
			SyncedLocation.OverrideSyncRate(SyncRate);
		if (SyncedTwoWayLocation != nullptr)
			SyncedTwoWayLocation.OverrideSyncRate(SyncRate);
	}

	bool HasFauxPhysicsControl() const override
	{
		if (SyncedLocation != nullptr)
			return SyncedLocation.HasControl();
		return true;
	}

	void ApplyForce(FVector Origin, FVector Force) override
	{
		if (!IsEnabled())
			return;

		PendingForces += Force * ForceScalar;
		Wake();
	}

	void ApplyImpulse(FVector Origin, FVector Impulse) override
	{
		if (!IsEnabled())
			return;

		PendingImpulses += Impulse * ForceScalar;
		Wake();
	}

	void ApplyMovement(FVector Origin, FVector Movement) override
	{
		if (!IsEnabled())
			return;

		FFauxPhysicsTranslateConstraint ConstraintZ = GetHeightConstraint();

		FVector LockedMovement = ApplyLockedConstraint(Movement, ConstraintZ);
		CurrentPhysicsLocation = GetWorldLocation() + LockedMovement;

		if(bConstrainWithSpline)
			ApplySplineConstraint();

		// Apply Z constraint
		// Note, if the axis is completely disabled (Min = Max), then we dont want to worry about constraining
		// We will simply filter out the forces on that axis.
		if (bConstrainZ && !ConstraintZ.bLocked)
			ApplyZConstraint(ConstraintZ);

		if(HasFauxPhysicsControl())
			ControlUpdateSyncedPosition();

		Wake();
	}

	FVector GetRelativeConstrainAxis(FVector Axis) const
	{
		return RelativeTransform.TransformVectorNoScale(Axis);
	}

	FVector GetWorldUp() const
	{
		return UpVector;
	}

	bool UpdateFauxPhysics(float InOriginalDeltaTime) override
	{
		if (SyncedTwoWayLocation != nullptr)
		{
			if (AttachParent == nullptr)
				CurrentPhysicsLocation = SyncedTwoWayLocation.Value;
			else
				CurrentPhysicsLocation = AttachParent.WorldTransform.TransformPosition(SyncedTwoWayLocation.Value);
		}
		else
		{
			CurrentPhysicsLocation = GetWorldLocation();
		}

		return Super::UpdateFauxPhysics(InOriginalDeltaTime);
	}

	private FFauxPhysicsTranslateConstraint GetHeightConstraint() const
	{
		float Offset = 0;

		switch(Shape)
		{
			case EFauxPhysicsSplineTranslateShape::Point:
				break;

			case EFauxPhysicsSplineTranslateShape::Cylinder:
				Offset = HalfHeight;
				break;

			case EFauxPhysicsSplineTranslateShape::Box:
				Offset = Extents.Z;
				break;
		}

		return FFauxPhysicsTranslateConstraint(MinZ + Offset, MaxZ - Offset);
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
			if (SpringStrength > SMALL_NUMBER && !RelativeLocation.Equals(SpringParentOffset))
				return false;

			// Don't sleep while moving
			if (!PendingImpulses.IsNearlyZero())
				return false;
			if (!PendingForces.IsNearlyZero())
				return false;
			if (!Velocity.IsNearlyZero())
				return false;

			if (SyncedTwoWayLocation != nullptr)
			{
				if (!SyncedTwoWayLocation.IsSleeping())
					return false;
			}
		}
		else
		{
			if (!SyncedLocation.IsSleeping())
				return false;
			if (!SyncedLocation.Value.Equals(RelativeLocation))
				return false;
		}

		return true;
	}

	protected void PhysicsStep(float DeltaTime) override
	{
		// Spring
		FVector SpringForces = FVector::ZeroVector;

		if (SpringStrength > SMALL_NUMBER)
		{
			FVector SpringRelativeLocation = CurrentPhysicsLocation;
			if (AttachParent != nullptr)
				SpringRelativeLocation = AttachParent.WorldTransform.InverseTransformPosition(SpringRelativeLocation);

			if (!SpringRelativeLocation.Equals(SpringParentOffset, 0.01))
			{
				FVector SpringOffset = SpringParentOffset - SpringRelativeLocation;

				// Get the direction in world space
				FVector SpringForce = SpringOffset;
				if (AttachParent != nullptr)
					SpringForce = AttachParent.WorldTransform.TransformVector(SpringOffset);

				SpringForces += SpringForce * SpringStrength;
			}
			else if (Velocity.SizeSquared() < 0.0001)
			{
				if (AttachParent != nullptr)
					CurrentPhysicsLocation = AttachParent.WorldTransform.TransformPosition(SpringParentOffset);
				else
					CurrentPhysicsLocation = SpringParentOffset;
			}
		}

		FVector TotalForce = PendingForces + SpringForces;
		Velocity += TotalForce * DeltaTime;
		Velocity += PendingImpulses;

		if (ConstrainedVerticalVelocity > KINDA_SMALL_NUMBER)
			Velocity.Z = Math::Min(Math::Abs(Velocity.Z), ConstrainedVerticalVelocity) * Math::Sign(Velocity.Z);
		if (ConstrainedHorizontalVelocity > KINDA_SMALL_NUMBER)
		{
			FVector HorizontalVelocity = Velocity;
			HorizontalVelocity.Z = 0.0;
			HorizontalVelocity = HorizontalVelocity.GetClampedToSize(0.0, ConstrainedHorizontalVelocity);
			Velocity.X = HorizontalVelocity.X;
			Velocity.Y = HorizontalVelocity.Y;
		}

		// Reset impulses right away, so we dont impulse on every step
		PendingImpulses = FVector::ZeroVector;

		// Apply friction
		if (Friction > SMALL_NUMBER)
		{
			float IntegratedFriction = Math::Exp(-Friction);
			Velocity *= Math::Pow(IntegratedFriction, DeltaTime);
		}

		FFauxPhysicsTranslateConstraint ConstraintZ = GetHeightConstraint();
		Velocity = ApplyLockedConstraint(Velocity, ConstraintZ);
		CurrentPhysicsLocation += Velocity * DeltaTime;

		if(bConstrainWithSpline)
			ApplySplineConstraint();

		// Apply Z constraint
		// Note, if the axis is completely disabled (Min = Max), then we dont want to worry about constraining
		// We will simply filter out the forces on that axis.
		if (bConstrainZ && !ConstraintZ.bLocked)
			ApplyZConstraint(ConstraintZ);
	}

	protected void ControlUpdateSyncedPosition() override
	{
		check(HasFauxPhysicsControl());
		
		SetWorldLocation(CurrentPhysicsLocation);

		if (SyncedLocation != nullptr)
			SyncedLocation.Value = GetRelativeLocation();
		else if (SyncedTwoWayLocation != nullptr)
			SyncedTwoWayLocation.Value = GetRelativeLocation();
	}

	protected void RemoteUpdateSyncedPosition() override
	{
		if (SyncedLocation == nullptr)
			return;

		check(!HasFauxPhysicsControl());

		SetRelativeLocation(SyncedLocation.Value);

		// Trigger impacts the control side sent to us
		float TrailTime = SyncedLocation.GetCrumbTrailReceiveTime();
		for (int i = QueuedImpacts.Num() - 1; i >= 0; --i)
		{
			// Impact hasn't been reached yet
			auto& QueuedImpact = QueuedImpacts[i];
			if (QueuedImpact.CrumbTrailTime > TrailTime)
				continue;

			// Apply the impact
			OnConstraintHit.Broadcast(QueuedImpact.SplinePosition, QueuedImpact.Edge, QueuedImpact.Strength);
			QueuedImpacts.RemoveAtSwap(i);
		}
	}

	void ResetForces() override
	{ 
		PendingForces = PendingImpulses = FVector::ZeroVector;
	}

	void ResetPhysics() override
	{ 
		Velocity = FVector::ZeroVector;
	}

	private void ApplySplineConstraint()
	{
		switch(Shape)
		{
			case EFauxPhysicsSplineTranslateShape::Point:
				ApplySplineConstraintForPoint();
				break;

			case EFauxPhysicsSplineTranslateShape::Cylinder:
				ApplySplineConstraintForCylinder();
				break;

			case EFauxPhysicsSplineTranslateShape::Box:
				ApplySplineConstraintForBox();
				break;
		}
	}

	private void ApplySplineConstraintForPoint()
	{
		FSplinePosition SplinePosition = GetClosestSplinePosition();
		FTransform SplineTransform = SplinePosition.WorldTransform;

		ConstrainTransformToWorldUp(SplineTransform);

		FVector RelativeToSpline = SplineTransform.InverseTransformPositionNoScale(CurrentPhysicsLocation);
		FVector HorizontalRelativeToSpline = RelativeToSpline.VectorPlaneProject(GetWorldUp());
		FVector VerticalRelativeToSpline = RelativeToSpline - HorizontalRelativeToSpline;

		TOptional<FVector> ImpactNormal;

		// Make sure that we are within the spline by clamping our location to the correct side,
		// based on the direction of the spline loop.
		if(bClockwise)
		{
			if(HorizontalRelativeToSpline.Y < 0)
			{
				// Outside the spline on the left side!
				// Clamp us to be inside the spline again
				HorizontalRelativeToSpline.Y = 0;
				ImpactNormal = SplineTransform.Rotation.RightVector;
			}
		}
		else
		{
			if(HorizontalRelativeToSpline.Y > 0)
			{
				// Outside the spline on the right side!
				// Clamp us to be inside the spline again
				HorizontalRelativeToSpline.Y = 0;
				ImpactNormal = -SplineTransform.Rotation.RightVector;
			}
		}

		if(ImpactNormal.IsSet())
		{
			RelativeToSpline = HorizontalRelativeToSpline + VerticalRelativeToSpline;
			CurrentPhysicsLocation = SplineTransform.TransformPositionNoScale(RelativeToSpline);

			TriggerImpact(SplinePosition, EFauxPhysicsSplineTranslateConstraintEdge::Spline, Math::Abs(Velocity.DotProduct(ImpactNormal.Value)));

			if (!Velocity.IsNearlyZero())
			{
				// We only bounce if we aren't already moving in the direction away from the boundary
				const bool bMovingIntoPlane = Velocity.DotProduct(ImpactNormal.Value) < 0;
				if (bMovingIntoPlane)
					Velocity -= Velocity.ConstrainToDirection(ImpactNormal.Value) * (1.0 + ConstrainBounce);
			}
		}
	}

	private void ApplySplineConstraintForCylinder()
	{
		FSplinePosition SplinePosition = GetClosestSplinePosition();
		FTransform SplineTransform = SplinePosition.WorldTransform;
		ConstrainTransformToWorldUp(SplineTransform);

		{
			// First, check if we are actually outside of the spline.
			// We should never end up outside, so this is a hard clamp.
			FVector RelativeToSpline = SplineTransform.InverseTransformPositionNoScale(CurrentPhysicsLocation);
			FVector HorizontalRelativeToSpline = RelativeToSpline.VectorPlaneProject(GetWorldUp());
			FVector VerticalRelativeToSpline = RelativeToSpline - HorizontalRelativeToSpline;

			bool bOutsideSpline = false;

			// Make sure that we are within the spline by clamping our location to the correct side,
			// based on the direction of the spline loop.
			if(bClockwise)
			{
				if(HorizontalRelativeToSpline.Y < 0)
				{
					// Outside the spline on the left side!
					// Clamp us to be inside the spline again
					HorizontalRelativeToSpline.Y = Radius;
					bOutsideSpline = true;
				}
			}
			else
			{
				if(HorizontalRelativeToSpline.Y > 0)
				{
					// Outside the spline on the right side!
					// Clamp us to be inside the spline again
					HorizontalRelativeToSpline.Y = -Radius;
					bOutsideSpline = true;
				}
			}

			if(bOutsideSpline)
			{
				RelativeToSpline = HorizontalRelativeToSpline + VerticalRelativeToSpline;
				CurrentPhysicsLocation = SplineTransform.TransformPositionNoScale(RelativeToSpline);
			}
		}

		// Adjust the spline transform based on our radius
		FVector PlaneNormal = CurrentPhysicsLocation - SplineTransform.Location;
		PlaneNormal = PlaneNormal.VectorPlaneProject(GetWorldUp()).GetSafeNormal();
		FVector PlaneLocation = SplineTransform.Location + PlaneNormal * Radius;

		// Create a plane out of the "wall" we should constrain on to
		FPlane Plane = FPlane(PlaneLocation, PlaneNormal);

		if(Plane.PlaneDot(CurrentPhysicsLocation) < 0)
		{
			// We are behind the wall!
			// Move us to the surface of the wall, and dispatch impacts
			CurrentPhysicsLocation = CurrentPhysicsLocation.PointPlaneProject(Plane.Origin, Plane.Normal);

			TriggerImpact(SplinePosition, EFauxPhysicsSplineTranslateConstraintEdge::Spline, Math::Abs(Velocity.DotProduct(PlaneNormal)));

			if (!Velocity.IsNearlyZero())
			{
				// We only bounce if we aren't already moving in the direction away from the boundary
				const bool bMovingIntoPlane = Velocity.DotProduct(PlaneNormal) < 0;
				if (bMovingIntoPlane)
					Velocity -= Velocity.ConstrainToDirection(PlaneNormal) * (1.0 + ConstrainBounce);
			}
		}
	}

	private void ApplySplineConstraintForBox()
	{
		Iteration++;

		FSplinePosition SplinePosition = GetClosestSplinePosition();
		FTransform SplineTransform = SplinePosition.WorldTransform;
		ConstrainTransformToWorldUp(SplineTransform);

		// FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		// TemporalLog.Transform(f"{Iteration};Spline Transform", SplineTransform);

		FVector SplineRelativeToBox = WorldTransform.InverseTransformPositionNoScale(SplineTransform.Location);
		SplineRelativeToBox.Z = 0;

		const FVector Extents2D = FVector(Extents.X, Extents.Y, 0);
		const FBox ShapeBox = FBox(-Extents2D, Extents2D);

		// The spline is not intersecting the box
		if(!ShapeBox.IsInsideOrOn(SplineRelativeToBox))
			return;

		float PenetrationX = Math::Abs(Math::Abs(SplineRelativeToBox.X) - Extents2D.X);
		float PenetrationY = Math::Abs(Math::Abs(SplineRelativeToBox.Y) - Extents2D.Y);

		// TemporalLog.Value(f"{Iteration};PenetrationX", PenetrationX);
		// TemporalLog.Value(f"{Iteration};PenetrationY", PenetrationY);

		FVector TargetPoint = SplineRelativeToBox;

		// Depenetrate the side with the smallest penetration
		if(PenetrationX < PenetrationY)
			TargetPoint.X = SplineRelativeToBox.X > 0.0 ? Extents2D.X : -Extents2D.X;
		else
			TargetPoint.Y = SplineRelativeToBox.Y > 0.0 ? Extents2D.Y : -Extents2D.Y;

		// Get delta to edge of the box
		FVector DepenetrationDelta = TargetPoint - SplineRelativeToBox;
		DepenetrationDelta = WorldTransform.TransformVectorNoScale(DepenetrationDelta);
		// TemporalLog.DirectionalArrow(f"{Iteration};DepenetrationDelta", WorldLocation, DepenetrationDelta);

		FVector ImpactNormal = -DepenetrationDelta.GetSafeNormal();
		
		CurrentPhysicsLocation -= DepenetrationDelta;

		TriggerImpact(SplinePosition, EFauxPhysicsSplineTranslateConstraintEdge::Spline, Math::Abs(Velocity.DotProduct(ImpactNormal)));

		if (!Velocity.IsNearlyZero())
		{
			// We only bounce if we aren't already moving in the direction away from the boundary
			const bool bMovingIntoPlane = Velocity.DotProduct(ImpactNormal) < 0;
			if (bMovingIntoPlane)
				Velocity -= Velocity.ConstrainToDirection(ImpactNormal) * (1.0 + ConstrainBounce);
		}
	}

	private FSplinePosition GetClosestSplinePosition() const
	{
		switch(Shape)
		{
			case EFauxPhysicsSplineTranslateShape::Point:
			case EFauxPhysicsSplineTranslateShape::Cylinder:
				return FindSplineComponentToUse().GetPlaneConstrainedClosestSplinePositionToWorldLocation(CurrentPhysicsLocation, GetWorldUp());

			case EFauxPhysicsSplineTranslateShape::Box:
			{
				const FVector Extents2D = FVector(Extents.X, Extents.Y, 0);
				const FBox ShapeBox = FBox(-Extents2D, Extents2D);

				const FSplinePosition FirstIteration = Spline.GetPlaneConstrainedClosestSplinePositionToWorldLocation(CurrentPhysicsLocation, GetWorldUp());
				const FVector FirstIterationRelative = WorldTransform.InverseTransformPositionNoScale(FirstIteration.WorldLocation);
				const FVector FirstRelativeClosestPointOnBox = ShapeBox.GetClosestPointTo(FirstIterationRelative);
				const FVector FirstClosestPointOnBox = WorldTransform.TransformPositionNoScale(FirstRelativeClosestPointOnBox);

				const FSplinePosition SecondIteration = Spline.GetPlaneConstrainedClosestSplinePositionToWorldLocation(FirstClosestPointOnBox, GetWorldUp());
				// const FVector SecondIterationRelative = WorldTransform.InverseTransformPositionNoScale(SecondIteration.WorldLocation);
				// const FVector SecondRelativeClosestPointOnBox = ShapeBox.GetClosestPointTo(SecondIterationRelative);
				// const FVector SecondClosestPointOnBox = WorldTransform.TransformPositionNoScale(SecondRelativeClosestPointOnBox);

				// const FSplinePosition ThirdIteration = Spline.GetPlaneConstrainedClosestSplinePositionToWorldLocation(SecondClosestPointOnBox, GetWorldUp());
				return SecondIteration;
			}
		}
	}

	/**
	 * Make sure that Transform up is constrained to WorldUp
	 */
	private void ConstrainTransformToWorldUp(FTransform& Transform)
	{
		FQuat Rotation = Transform.Rotation;
		Rotation = FQuat::MakeFromZX(GetWorldUp(), Rotation.ForwardVector);
		Transform.SetRotation(Rotation);
	}

	// If we have completely disabled an axis (through constraints), we want to filter that away from all forces :)
	// That way we dont have to worry about keeping us constrained within that point
	private FVector ApplyLockedConstraint(FVector Vec, FFauxPhysicsTranslateConstraint ConstraintZ)
	{
		FVector LockedVec = Vec;
		if (bConstrainZ && ConstraintZ.bLocked)
			LockedVec = LockedVec.ConstrainToPlane(GetWorldUp());

		return LockedVec;
	}

	private void ApplyZConstraint(FFauxPhysicsTranslateConstraint ConstraintZ)
	{
		FVector RelativeAxis = GetRelativeConstrainAxis(FVector::UpVector);
		FVector WorldAxis = GetWorldUp();

		// We want the clamps to work in relative space, which is why we use "RelativeAxis" here
		FTransform AttachTransform = FTransform::Identity;
		if (AttachParent != nullptr)
			AttachTransform = AttachParent.WorldTransform;

		FVector RelativePosition = AttachTransform.InverseTransformPosition(CurrentPhysicsLocation);
		FVector SpringOffset = RelativePosition - SpringParentOffset;
		float RelativeLocationDot = RelativeAxis.DotProduct(SpringOffset);

		if (RelativeLocationDot < ConstraintZ.Min - 0.0001 || RelativeLocationDot > ConstraintZ.Max + 0.0001)
		{
			EFauxPhysicsSplineTranslateConstraintEdge Edge = EFauxPhysicsSplineTranslateConstraintEdge::AxisZ_Min;
			if (RelativeLocationDot > ConstraintZ.Max)
				Edge = EFauxPhysicsSplineTranslateConstraintEdge::AxisZ_Max;

			TriggerImpact(FSplinePosition(), Edge, Math::Abs(Velocity.DotProduct(WorldAxis)));

			// Velocity is in world space, which is why we use "WorldAxis" here.
			if (!Velocity.IsNearlyZero())
			{
				// We only bounce if we aren't already moving in the direction away from the boundary
				float VelocityDirectionOnAxis = Math::Sign(Velocity.DotProduct(WorldAxis));
				float ConstraintDirectionOnAxis = Math::Sign(RelativeLocationDot);
				if (VelocityDirectionOnAxis == ConstraintDirectionOnAxis)
					Velocity -= Velocity.ConstrainToDirection(WorldAxis) * (1.0 + ConstrainBounce);
			}

			RelativeLocationDot = Math::Clamp(RelativeLocationDot, ConstraintZ.Min, ConstraintZ.Max);
			// Constrain offset
			SpringOffset = SpringOffset.ConstrainToPlane(RelativeAxis) + RelativeAxis * RelativeLocationDot;

			// Move the component to where we're clamped
			CurrentPhysicsLocation = AttachTransform.TransformPosition(SpringParentOffset + SpringOffset);
		}
	}

	UFUNCTION()
	FVector GetVelocity() const
	{
		return Velocity;
	}

	void SetVelocity(FVector NewVelocity)
	{
		Velocity = NewVelocity;
	}

	private TArray<FFauxPhysicsSplineTranslateImpact> QueuedImpacts;
	private float IgnoreImpactsUntil = 0.0;

	private void TriggerImpact(FSplinePosition SplinePosition, EFauxPhysicsSplineTranslateConstraintEdge Edge, float Strength)
	{
		if (Strength < ImpactMinStrength)
			return;
		if (Time::GameTimeSeconds < IgnoreImpactsUntil)
			return;

		IgnoreImpactsUntil = Time::GameTimeSeconds + MinTimeBetweenImpacts;

		OnConstraintHit.Broadcast(SplinePosition, Edge, Strength);

		if (SyncedLocation != nullptr && HasFauxPhysicsControl() && FauxPhysics::Calculation::CVar_DropAllRemoteImpacts.GetInt() == 0)
		{
			if (OnConstraintHit.IsBound())
			{
				NetSendImpact(
					SyncedLocation.GetCrumbTrailSendTime(),
					SplinePosition,
					Edge,
					Strength
				);
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetSendImpact(float CrumbTrailTime, FSplinePosition SplinePosition, EFauxPhysicsSplineTranslateConstraintEdge Edge, float Strength)
	{
		if (HasFauxPhysicsControl())
			return;

		FFauxPhysicsSplineTranslateImpact Impact;
		Impact.CrumbTrailTime = CrumbTrailTime;
		Impact.SplinePosition = SplinePosition;
		Impact.Edge = Edge;
		Impact.Strength = Strength;
		QueuedImpacts.Add(Impact);
	}
};

struct FFauxPhysicsSplineTranslateImpact
{
	float CrumbTrailTime;
	FSplinePosition SplinePosition;
	EFauxPhysicsSplineTranslateConstraintEdge Edge;
	float Strength;
};

class UFauxPhysicsSplineTranslateComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UFauxPhysicsSplineTranslateComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto SplineTranslateComponent = Cast<UFauxPhysicsSplineTranslateComponent>(Component);
		if(SplineTranslateComponent == nullptr)
			return;

		bool bSkipZ = SplineTranslateComponent.bConstrainZ && Math::IsNearlyEqual(SplineTranslateComponent.MinZ, SplineTranslateComponent.MaxZ);

		FVector Origin = SplineTranslateComponent.GetRelativeLocation();
		FTransform AttachTransform;
		if (SplineTranslateComponent.AttachParent != nullptr)
		{
			Origin = SplineTranslateComponent.AttachParent.WorldTransform.TransformPosition(Origin);
			AttachTransform = SplineTranslateComponent.AttachParent.WorldTransform;
		}

		if(SplineTranslateComponent.bConstrainWithSpline)
		{
			DrawCircle(
				SplineTranslateComponent.WorldLocation,
				SplineTranslateComponent.Radius,
				FLinearColor::Red,
				3,
				SplineTranslateComponent.UpVector
			);

			switch(SplineTranslateComponent.Shape)
			{
				case EFauxPhysicsSplineTranslateShape::Point:
					break;

				case EFauxPhysicsSplineTranslateShape::Cylinder:
					DrawWireCylinder(
						SplineTranslateComponent.WorldLocation,
						SplineTranslateComponent.WorldRotation,
						FLinearColor::LucBlue,
						SplineTranslateComponent.Radius,
						SplineTranslateComponent.HalfHeight,
						16,
						3
					);
					break;

				case EFauxPhysicsSplineTranslateShape::Box:
					DrawWireBox(
						SplineTranslateComponent.WorldLocation,
						SplineTranslateComponent.Extents,
						SplineTranslateComponent.ComponentQuat,
						FLinearColor::LucBlue,
						3
					);
					break;
			}

			const UHazeSplineComponent Spline = SplineTranslateComponent.FindSplineComponentToUse();

			if(Spline != nullptr)
			{
				const float SplineLength = Spline.SplineLength;
				float Distance = 0;
				const int Steps = Math::Min(Math::IntegerDivisionTrunc(Math::RoundToInt(SplineLength), 100), 150);
				const float DistancePerStep = Spline.SplineLength / Steps;

				const FVector WorldUp = SplineTranslateComponent.GetWorldUp();
				float MinLength = 100;
				float MaxLength = 100;
				if(SplineTranslateComponent.bConstrainZ)
				{
					MinLength = Math::Max(MinLength, Math::Abs(SplineTranslateComponent.MinZ));
					MaxLength = Math::Max(MaxLength, SplineTranslateComponent.MaxZ);
				}

				while(Distance < SplineLength)
				{
					Distance = Distance + DistancePerStep;

					FVector Location = Spline.GetWorldLocationAtSplineDistance(Distance);
					Location = Location.PointPlaneProject(SplineTranslateComponent.WorldLocation, SplineTranslateComponent.GetWorldUp());
					DrawLine(Location - (WorldUp * MinLength), Location + (WorldUp * MaxLength), FLinearColor::Red, 3, true);
				}
			}
		}

		if (!bSkipZ)
			DrawTranslateAxis(Origin, AttachTransform.TransformVector(FVector::UpVector), FLinearColor::Blue, SplineTranslateComponent.bConstrainZ, SplineTranslateComponent.MinZ, SplineTranslateComponent.MaxZ);
	}

	void DrawTranslateAxis(FVector Location, FVector Axis, FLinearColor Color, bool bConstrained, float Min, float Max)
	{
		if (bConstrained)
		{
			DrawLine(Location, Location + Axis * Max, Color, 5.0);
			DrawLine(Location, Location + Axis * Min, Color * 0.4, 5.0);

			DrawCircle(Location + Axis * Max, 100.0, Color, 5.0, Axis.GetSafeNormal());
			DrawCircle(Location + Axis * Min, 100.0, Color * 0.4, 5.0, Axis.GetSafeNormal());
		}
		else
		{
			DrawArrow(Location, Location + Axis * 250.0, Color, 25.0, 5.0);
			DrawArrow(Location, Location - Axis * 250.0, Color, 25.0, 5.0);
		}
	}
};