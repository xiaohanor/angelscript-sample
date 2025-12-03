enum EFauxPhysicsTranslateNetworkMode
{
	// Position is not networked, but simulated fully locally. Impacts happen on both sides independently.
	Local,
	// Position is synced from the actor's control side that owns the faux physics component. Impacts synced.
	SyncedFromActorControl,
	// Position is synced always from Mio's side. Impacts are synced.
	SyncedFromMioControl,
	// Position is synced always from Zoe's side. Impacts are synced.
	SyncedFromZoeControl,
	/**
	 * Position is independently calculated on both sides, and then interpolated to slowly reduce the error between them.
	 * OBS! This changes physics behavior compared to local, as the interpolation makes the physics forces a bit smaller!
	 * OBS! Impact delegates still happen independently on both sides, and are not synced!
	 */
	TwoWaySynced,
};

// Edges are "encoded" in a particular way
// Each axis is aligned 0-2, naturally.
// However, the MAXIMUM of a constraint is "encoded" as axis + 4
// This makes constructing the enum a bit easier
enum EFauxPhysicsTranslateConstraintEdge
{
	AxisX_Min = 0,
	AxisX_Max = 4,

	AxisY_Min = 1,
	AxisY_Max = 5,

	AxisZ_Min = 2,
	AxisZ_Max = 6,
}

enum EFauxPhysicsTranslateShape
{
	Point,
	Sphere,
	Box,
};

struct FFauxPhysicsTranslateConstraint
{
	bool bLocked;
	float Min;
	float Max;

	FFauxPhysicsTranslateConstraint(float InMin, float InMax)
	{
		Min = Math::Min(InMin, InMax);
		Max = Math::Max(InMax, InMin);
		bLocked = Math::IsNearlyEqual(Min, Max);
	}
};

event void FFauxPhysicsTranslateConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength);

UCLASS(ClassGroup = FauxPhysics, Meta = (HideCategories = "LOD Physics AssetUserData Collision Tags Cooking Activation Rendering"))
class UFauxPhysicsTranslateComponent : UFauxPhysicsComponentBase
{
	access EditAndReadOnly = private, * (editdefaults, readonly);

	private FVector Velocity;
	private FVector PendingForces;
	private FVector PendingImpulses;

	UPROPERTY(Category = "FauxPhysics", EditAnywhere)
	float Friction = 2.4;

	UPROPERTY(Category = "FauxPhysics", EditAnywhere)
	float ForceScalar = 1.0;

	/**
	 * Internally changes the constraint extents to visually match the shape.
	 */
	UPROPERTY(Category = "Shape", EditAnywhere)
	EFauxPhysicsTranslateShape Shape = EFauxPhysicsTranslateShape::Point;

	UPROPERTY(Category = "Shape", EditAnywhere, Meta = (EditCondition = "Shape == EFauxPhysicsTranslateShape::Sphere", EditConditionHides))
	float Radius = 100;

	UPROPERTY(Category = "Shape", EditAnywhere, Meta = (EditCondition = "Shape == EFauxPhysicsTranslateShape::Box", EditConditionHides))
	FVector Extents = FVector(100);

	UPROPERTY(Category = "Constraints", EditAnywhere)
	bool bConstrainX = false;

	UPROPERTY(Category = "Constraints", EditAnywhere, Meta = (EditCondition = "bConstrainX", EditConditionHides))
	float MinX = 0.0;

	UPROPERTY(Category = "Constraints", EditAnywhere, Meta = (EditCondition = "bConstrainX", EditConditionHides))
	float MaxX = 0.0;

	UPROPERTY(Category = "Constraints", EditAnywhere)
	bool bConstrainY = false;

	UPROPERTY(Category = "Constraints", EditAnywhere, Meta = (EditCondition = "bConstrainY", EditConditionHides))
	float MinY = 0.0;

	UPROPERTY(Category = "Constraints", EditAnywhere, Meta = (EditCondition = "bConstrainY", EditConditionHides))
	float MaxY = 0.0;

	UPROPERTY(Category = "Constraints", EditAnywhere)
	bool bConstrainZ = false;

	UPROPERTY(Category = "Constraints", EditAnywhere, Meta = (EditCondition = "bConstrainZ", EditConditionHides))
	float MinZ = 0.0;

	UPROPERTY(Category = "Constraints", EditAnywhere, Meta = (EditCondition = "bConstrainZ", EditConditionHides))
	float MaxZ = 0.0;

	UPROPERTY(Category = "Constraints", EditAnywhere, Meta = (EditCondition = "bConstrainX || bConstrainY || bConstrainZ"))
	float ConstrainBounce = 0.5;

	UPROPERTY(Category = "Spring", EditAnywhere)
	float SpringStrength = 0.0;

	UPROPERTY()
	FFauxPhysicsTranslateConstraintHit OnConstraintHit;

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
		if (MinX > MaxX)
			Swap(MinX, MaxX);

		if (MinY > MaxY)
			Swap(MinY, MaxY);
		
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

	/**
	 * Map the current position to alpha values between 0 and 1,
	 * where 0 indicates the minimum constraint and 1 indicates the maximum constraint.
	 * 
	 * NB. Dimensions that are unconstrained will always return 0 alpha.
	 * NB. Dimensions constrained to a single static value will always return 0 alpha.
	 */
	UFUNCTION(BlueprintPure)
	FVector GetCurrentAlphaBetweenConstraints()
	{
		FVector CurrentRelativeLocation = GetRelativeLocation();
		FVector AlphaValues;

		const FFauxPhysicsTranslateConstraint ConstraintX = MakeConstraintForAxis(EAxis::X);
		const FFauxPhysicsTranslateConstraint ConstraintY = MakeConstraintForAxis(EAxis::Y);
		const FFauxPhysicsTranslateConstraint ConstraintZ = MakeConstraintForAxis(EAxis::Z);

		if (bConstrainX && !ConstraintX.bLocked)
			AlphaValues.X = (CurrentRelativeLocation.X - SpringParentOffset.X - ConstraintX.Min) / (ConstraintX.Max - ConstraintX.Min);
		if (bConstrainY && !ConstraintY.bLocked)
			AlphaValues.Y = (CurrentRelativeLocation.Y - SpringParentOffset.Y - ConstraintY.Min) / (ConstraintY.Max - ConstraintY.Min);
		if (bConstrainZ && !ConstraintZ.bLocked)
			AlphaValues.Z = (CurrentRelativeLocation.Z - SpringParentOffset.Z - ConstraintZ.Min) / (ConstraintZ.Max - ConstraintZ.Min);

		return AlphaValues;
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

		const FFauxPhysicsTranslateConstraint ConstraintX = MakeConstraintForAxis(EAxis::X);
		const FFauxPhysicsTranslateConstraint ConstraintY = MakeConstraintForAxis(EAxis::Y);
		const FFauxPhysicsTranslateConstraint ConstraintZ = MakeConstraintForAxis(EAxis::Z);
		
		FVector LockedMovement = ApplyLockedConstraints(Movement, ConstraintX, ConstraintY, ConstraintZ);
		CurrentPhysicsLocation = GetWorldLocation() + LockedMovement;

		// Apply constraints
		// Note, if the axis is completely disabled (Min = Max), then we dont want to worry about constraining
		// We will simply filter out the forces on that axis.
		if (bConstrainX && !ConstraintX.bLocked)
			ApplyConstraint(FVector::ForwardVector, ConstraintX, FVector::ZeroVector);

		if (bConstrainY && !ConstraintY.bLocked)
			ApplyConstraint(FVector::RightVector, ConstraintY, FVector::ZeroVector);

		if (bConstrainZ && !ConstraintZ.bLocked)
			ApplyConstraint(FVector::UpVector, ConstraintZ, FVector::ZeroVector);

		if(HasFauxPhysicsControl())
			ControlUpdateSyncedPosition();

		Wake();
	}

	FVector GetWorldLocationAfterConstraints(FVector InWorldLocation)
	{
		FVector OutLocation = InWorldLocation;

		if (bConstrainX)
		{
			const FFauxPhysicsTranslateConstraint ConstraintX = MakeConstraintForAxis(EAxis::X);
			OutLocation = GetWorldLocationAfterConstraintAxis(OutLocation, FVector::ForwardVector, ConstraintX);
		}

		if (bConstrainY)
		{
			const FFauxPhysicsTranslateConstraint ConstraintY = MakeConstraintForAxis(EAxis::Y);
			OutLocation = GetWorldLocationAfterConstraintAxis(OutLocation, FVector::RightVector, ConstraintY);
		}

		if (bConstrainZ)
		{
			const FFauxPhysicsTranslateConstraint ConstraintZ = MakeConstraintForAxis(EAxis::Z);
			OutLocation = GetWorldLocationAfterConstraintAxis(OutLocation, FVector::UpVector, ConstraintZ);
		}

		return OutLocation;
	}

	private FVector GetWorldLocationAfterConstraintAxis(FVector InWorldLocation, FVector ConstraintAxis, FFauxPhysicsTranslateConstraint Constraint) const
	{
		FVector RelativeAxis = GetRelativeConstrainAxis(ConstraintAxis);

		// We want the clamps to work in relative space, which is why we use "RelativeAxis" here
		FTransform AttachTransform = FTransform::Identity;
		if (AttachParent != nullptr)
			AttachTransform = AttachParent.WorldTransform;

		FVector RelativePosition = AttachTransform.InverseTransformPosition(InWorldLocation);
		FVector SpringOffset = RelativePosition - SpringParentOffset;
		float RelativeLocationDot = RelativeAxis.DotProduct(SpringOffset);

		if (RelativeLocationDot < Constraint.Min - 0.0001 || RelativeLocationDot > Constraint.Max + 0.0001)
		{
			RelativeLocationDot = Math::Clamp(RelativeLocationDot, Constraint.Min, Constraint.Max);

			// Constrain offset
			SpringOffset = SpringOffset.ConstrainToPlane(RelativeAxis) + RelativeAxis * RelativeLocationDot;

			// Move the component to where we're clamped
			return AttachTransform.TransformPosition(SpringParentOffset + SpringOffset);
		}
		else
		{
			return InWorldLocation;
		}
	}

	FVector GetRelativeConstrainAxis(FVector Axis) const
	{
		return RelativeTransform.TransformVectorNoScale(Axis);
	}

	FVector GetWorldConstrainAxis(FVector Axis) const
	{
		return WorldTransform.TransformVectorNoScale(Axis);
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

	private FFauxPhysicsTranslateConstraint MakeConstraintForAxis(EAxis Axis) const
	{
		float Offset = 0;

		switch(Shape)
		{
			case EFauxPhysicsTranslateShape::Point:
				break;

			case EFauxPhysicsTranslateShape::Sphere:
				Offset = Radius;
				break;

			case EFauxPhysicsTranslateShape::Box:
				Offset = Extents[int(Axis) - 1];	// EAxis::0 is None, 1 is X
				break;
		}

		switch(Axis)
		{
			case EAxis::X:
				return FFauxPhysicsTranslateConstraint(MinX + Offset, MaxX - Offset);

			case EAxis::Y:
				return FFauxPhysicsTranslateConstraint(MinY + Offset, MaxY - Offset);

			case EAxis::Z:
				return FFauxPhysicsTranslateConstraint(MinZ + Offset, MaxZ - Offset);

			default:
				check(false);
				return FFauxPhysicsTranslateConstraint();
		}
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

		FVector StepMovement = Velocity * DeltaTime;
		StepMovement += PendingImpulses * DeltaTime;
		StepMovement += (PendingForces + SpringForces) * (DeltaTime * DeltaTime * 0.5);

		FVector TotalForce = PendingForces + SpringForces;
		Velocity += TotalForce * DeltaTime;
		Velocity += PendingImpulses;

		// Reset impulses right away, so we dont impulse on every step
		PendingImpulses = FVector::ZeroVector;

		// Apply friction
		if (Friction > SMALL_NUMBER)
		{
			float IntegratedFriction = Math::Exp(-Friction);
			Velocity *= Math::Pow(IntegratedFriction, DeltaTime);
		}

		const FFauxPhysicsTranslateConstraint ConstraintX = MakeConstraintForAxis(EAxis::X);
		const FFauxPhysicsTranslateConstraint ConstraintY = MakeConstraintForAxis(EAxis::Y);
		const FFauxPhysicsTranslateConstraint ConstraintZ = MakeConstraintForAxis(EAxis::Z);

		Velocity = ApplyLockedConstraints(Velocity, ConstraintX, ConstraintY, ConstraintZ);
		StepMovement = ApplyLockedConstraints(StepMovement, ConstraintX, ConstraintY, ConstraintZ);

		CurrentPhysicsLocation += StepMovement;

		// Apply constraints
		// Note, if the axis is completely disabled (Min = Max), then we dont want to worry about constraining
		// We will simply filter out the forces on that axis.
		if (bConstrainX && !ConstraintX.bLocked)
			ApplyConstraint(FVector::ForwardVector, ConstraintX, PendingForces * DeltaTime);
		if (bConstrainY && !ConstraintY.bLocked)
			ApplyConstraint(FVector::RightVector, ConstraintY, PendingForces * DeltaTime);
		if (bConstrainZ && !ConstraintZ.bLocked)
			ApplyConstraint(FVector::UpVector, ConstraintZ, PendingForces * DeltaTime);
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
			OnConstraintHit.Broadcast(QueuedImpact.Edge, QueuedImpact.Strength);
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

	// If we have completely disabled an axis (through constraints), we want to filter that away from all forces :)
	// That way we dont have to worry about keeping us constrained within that point
	private FVector ApplyLockedConstraints(
		FVector Vec,
		FFauxPhysicsTranslateConstraint ConstraintX,
		FFauxPhysicsTranslateConstraint ConstraintY,
		FFauxPhysicsTranslateConstraint ConstraintZ
	)
	{
		FVector LockedVec = Vec;

		if (bConstrainX && ConstraintX.bLocked)
			LockedVec = LockedVec.ConstrainToPlane(GetWorldConstrainAxis(FVector::ForwardVector));

		if (bConstrainY && ConstraintY.bLocked)
			LockedVec = LockedVec.ConstrainToPlane(GetWorldConstrainAxis(FVector::RightVector));

		if (bConstrainZ && ConstraintZ.bLocked)
			LockedVec = LockedVec.ConstrainToPlane(GetWorldConstrainAxis(FVector::UpVector));

		return LockedVec;
	}

	// NOTE: Axis is not in any particular space, its just "FVector::ForwardVector" or similar.
	// So it will have to be transformed into Local or World space manually, because both are used
	private void ApplyConstraint(FVector Axis, FFauxPhysicsTranslateConstraint Constraint, FVector BounceCutoffSpeed)
	{
		FVector RelativeAxis = GetRelativeConstrainAxis(Axis);
		FVector WorldAxis = GetWorldConstrainAxis(Axis);

		// We want the clamps to work in relative space, which is why we use "RelativeAxis" here
		FTransform AttachTransform = FTransform::Identity;
		if (AttachParent != nullptr)
			AttachTransform = AttachParent.WorldTransform;

		FVector RelativePosition = AttachTransform.InverseTransformPosition(CurrentPhysicsLocation);
		FVector SpringOffset = RelativePosition - SpringParentOffset;
		float RelativeLocationDot = RelativeAxis.DotProduct(SpringOffset);

		if (RelativeLocationDot < Constraint.Min - 0.0001 || RelativeLocationDot > Constraint.Max + 0.0001)
		{
			EFauxPhysicsTranslateConstraintEdge Edge;
			if (Axis == FVector::ForwardVector) Edge = EFauxPhysicsTranslateConstraintEdge::AxisX_Min;
			else if (Axis == FVector::RightVector) Edge = EFauxPhysicsTranslateConstraintEdge::AxisY_Min;
			else if (Axis == FVector::UpVector) Edge = EFauxPhysicsTranslateConstraintEdge::AxisZ_Min;
			else Edge = EFauxPhysicsTranslateConstraintEdge::AxisX_Min;

			// The enum is set up so that Max-edges is offset by 4
			if (RelativeLocationDot > Constraint.Max)
				Edge = EFauxPhysicsTranslateConstraintEdge(int(Edge) + 4);

			TriggerImpact(Edge, Math::Abs(Velocity.DotProduct(WorldAxis)));

			// Velocity is in world space, which is why we use "WorldAxis" here.
			if (!Velocity.IsNearlyZero())
			{
				// We only bounce if we aren't already moving in the direction away from the boundary
				float VelocityDirectionOnAxis = Math::Sign(Velocity.DotProduct(WorldAxis));
				float ConstraintDirectionOnAxis = Math::Sign(RelativeLocationDot);
				if (VelocityDirectionOnAxis == ConstraintDirectionOnAxis)
				{
					Velocity -= Velocity.ConstrainToDirection(WorldAxis) * (1.0 + ConstrainBounce);
					if (Math::Abs(Velocity.DotProduct(WorldAxis)) < Math::Abs(BounceCutoffSpeed.DotProduct(WorldAxis)))
						Velocity = Velocity.ConstrainToPlane(WorldAxis);
				}
			}

			RelativeLocationDot = Math::Clamp(RelativeLocationDot, Constraint.Min, Constraint.Max);
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

	private TArray<FFauxPhysicsTranslateImpact> QueuedImpacts;
	private float IgnoreImpactsUntil = 0.0;

	private void TriggerImpact(EFauxPhysicsTranslateConstraintEdge Edge, float Strength)
	{
		if (Strength < ImpactMinStrength)
			return;
		if (Time::GameTimeSeconds < IgnoreImpactsUntil)
			return;

		IgnoreImpactsUntil = Time::GameTimeSeconds + MinTimeBetweenImpacts;

		OnConstraintHit.Broadcast(Edge, Strength);

		if (SyncedLocation != nullptr && HasFauxPhysicsControl() && FauxPhysics::Calculation::CVar_DropAllRemoteImpacts.GetInt() == 0)
		{
			if (OnConstraintHit.IsBound())
			{
				NetSendImpact(
					SyncedLocation.GetCrumbTrailSendTime(),
					Edge,
					Strength
				);
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetSendImpact(float CrumbTrailTime, EFauxPhysicsTranslateConstraintEdge Edge, float Strength)
	{
		if (HasFauxPhysicsControl())
			return;

		FFauxPhysicsTranslateImpact Impact;
		Impact.CrumbTrailTime = CrumbTrailTime;
		Impact.Edge = Edge;
		Impact.Strength = Strength;
		QueuedImpacts.Add(Impact);
	}
}

struct FFauxPhysicsTranslateImpact
{
	float CrumbTrailTime;
	float Strength;
	EFauxPhysicsTranslateConstraintEdge Edge;
}

#if EDITOR
class UFauxPhysicsTranslateComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UFauxPhysicsTranslateComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		UFauxPhysicsTranslateComponent TranslateComponent = Cast<UFauxPhysicsTranslateComponent>(Component);

		switch(TranslateComponent.Shape)
		{
			case EFauxPhysicsTranslateShape::Point:
				break;

			case EFauxPhysicsTranslateShape::Sphere:
				DrawWireSphere(TranslateComponent.WorldLocation, TranslateComponent.Radius, FLinearColor::LucBlue, 5);
				break;

			case EFauxPhysicsTranslateShape::Box:
				DrawWireBox(TranslateComponent.WorldLocation, TranslateComponent.Extents, TranslateComponent.ComponentQuat, FLinearColor::LucBlue, 5);
				break;
		}

		bool bSkipX = TranslateComponent.bConstrainX && Math::IsNearlyEqual(TranslateComponent.MinX, TranslateComponent.MaxX);
		bool bSkipY = TranslateComponent.bConstrainY && Math::IsNearlyEqual(TranslateComponent.MinY, TranslateComponent.MaxY);
		bool bSkipZ = TranslateComponent.bConstrainZ && Math::IsNearlyEqual(TranslateComponent.MinZ, TranslateComponent.MaxZ);

		FVector Origin = TranslateComponent.GetRelativeLocation();
		if(Editor::IsPlaying())
			Origin = TranslateComponent.SpringParentOffset;
		
		FTransform AttachTransform;
		if (TranslateComponent.AttachParent != nullptr)
		{
			Origin = TranslateComponent.AttachParent.WorldTransform.TransformPosition(Origin);
			AttachTransform = TranslateComponent.AttachParent.WorldTransform;
		}

		if (!bSkipX)
			DrawTranslateAxis(Origin, AttachTransform.TransformVector(FVector::ForwardVector), FLinearColor::Red, TranslateComponent.bConstrainX, TranslateComponent.MinX, TranslateComponent.MaxX);
		if (!bSkipY)
			DrawTranslateAxis(Origin, AttachTransform.TransformVector(FVector::RightVector), FLinearColor::Green, TranslateComponent.bConstrainY, TranslateComponent.MinY, TranslateComponent.MaxY);
		if (!bSkipZ)
			DrawTranslateAxis(Origin, AttachTransform.TransformVector(FVector::UpVector), FLinearColor::Blue, TranslateComponent.bConstrainZ, TranslateComponent.MinZ, TranslateComponent.MaxZ);
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
#endif