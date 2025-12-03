enum EFauxPhysicsTranslateCircleConstraintNormal
{
	Forward,
	Right,
	Up,
}

struct FFauxPhysicsCircleTranslateImpact
{
	float CrumbTrailTime;
	float Strength;
}

event void FFauxPhysicsCircleTranslateConstraintHit(float HitStrength);

UCLASS(ClassGroup = FauxPhysics, Meta = (HideCategories = "LOD Physics AssetUserData Collision Tags Cooking Activation Rendering"))
class UFauxPhysicsCircleTranslateComponent : UFauxPhysicsComponentBase
{
	access EditAndReadOnly = private, * (editdefaults, readonly);

	private FVector Velocity;
	private FVector PendingForces;
	private FVector PendingImpulses;

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	float Friction = 2.4;

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	float ForceScalar = 1.0;

	UPROPERTY(Category = Constraints, EditAnywhere)
	float CircleRadius = 500.0;

	UPROPERTY(Category = Constraints, EditAnywhere)
	float ConstrainBounce = 0.5;

	UPROPERTY(Category = Constraints, EditAnywhere)
	EFauxPhysicsTranslateCircleConstraintNormal CircleNormal = EFauxPhysicsTranslateCircleConstraintNormal::Up;

	UPROPERTY(Category = Spring, EditAnywhere)
	float SpringStrength = 0.0;

	// Minimum strength to hit the constraint before an impact event is sent
	UPROPERTY(EditAnywhere, Category = "Impacts")
	float ImpactMinStrength = 50.0;

	// Minimum interval between impacts being registered
	UPROPERTY(EditAnywhere, Category = "Impacts")
	float MinTimeBetweenImpacts = 0.5;

	UPROPERTY(EditAnywhere, Category = "Network")
	access:EditAndReadOnly
	EFauxPhysicsTranslateNetworkMode NetworkMode = EFauxPhysicsTranslateNetworkMode::Local;

	UPROPERTY()
	FFauxPhysicsCircleTranslateConstraintHit OnConstraintHit;

	FVector SpringParentOffset;

	private FVector CurrentPhysicsLocation;

	private UHazeCrumbSyncedVectorComponent SyncedLocation; 
	private UHazeTwoWaySyncedVectorComponent SyncedTwoWayLocation;

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

		// Negative circle radius is invalid
		if(CircleRadius < 0)
			CircleRadius = 0;
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

		FVector LockedMovement = Movement;
		ApplyLockedConstraints(LockedMovement);
		CurrentPhysicsLocation = GetWorldLocation() + LockedMovement;

		// Apply constraints
		ApplyConstraints();

		if(HasFauxPhysicsControl())
			ControlUpdateSyncedPosition();

		Wake();
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

		const FVector TotalForce = PendingForces + SpringForces;

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

		ApplyLockedConstraints(Velocity);

		CurrentPhysicsLocation += Velocity * DeltaTime;

		// Apply constraints
		ApplyConstraints();
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
			OnConstraintHit.Broadcast(QueuedImpact.Strength);
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

	UFUNCTION()
	FVector GetVelocity() const
	{
		return Velocity;
	}

	void SetVelocity(FVector NewVelocity)
	{
		Velocity = NewVelocity;
	}

	private TArray<FFauxPhysicsCircleTranslateImpact> QueuedImpacts;
	private float IgnoreImpactsUntil = 0.0;

	private void TriggerImpact(float Strength)
	{
		if (Strength < ImpactMinStrength)
			return;
		if (Time::GameTimeSeconds < IgnoreImpactsUntil)
			return;

		IgnoreImpactsUntil = Time::GameTimeSeconds + MinTimeBetweenImpacts;

		OnConstraintHit.Broadcast(Strength);

		if (SyncedLocation != nullptr && HasFauxPhysicsControl() && FauxPhysics::Calculation::CVar_DropAllRemoteImpacts.GetInt() == 0)
		{
			if (OnConstraintHit.IsBound())
			{
				NetSendImpact(
					SyncedLocation.GetCrumbTrailSendTime(),
					Strength
				);
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetSendImpact(float CrumbTrailTime, float Strength)
	{
		if (HasFauxPhysicsControl())
			return;

		FFauxPhysicsCircleTranslateImpact Impact;
		Impact.CrumbTrailTime = CrumbTrailTime;
		Impact.Strength = Strength;
		QueuedImpacts.Add(Impact);
	}

	/**
	 * Constraints
	 */

	private void ApplyConstraints()
	{
		const FVector RelativeNormal = GetRelativeConstrainAxis(GetCircleConstraintNormalVector());

		FTransform AttachTransform = FTransform::Identity;
		if (AttachParent != nullptr)
			AttachTransform = AttachParent.WorldTransform;

		const FVector RelativePosition = AttachTransform.InverseTransformPosition(CurrentPhysicsLocation);

		FVector SpringOffset = RelativePosition - SpringParentOffset;

		// Project on to the circle normal
		SpringOffset = SpringOffset.VectorPlaneProject(RelativeNormal);
		
		if(SpringOffset.Size() > CircleRadius)
		{
			const FVector WorldDirection = AttachTransform.TransformVectorNoScale(SpringOffset).GetSafeNormal();

			TriggerImpact(Math::Abs(Velocity.DotProduct(WorldDirection)));

			// Velocity is in world space
			if (!Velocity.IsNearlyZero())
			{
				// We only bounce if we aren't already moving in the direction away from the boundary
				float VelocityDirectionOnAxis = Math::Sign(Velocity.DotProduct(WorldDirection));
				if (VelocityDirectionOnAxis > 0)
					Velocity -= Velocity.ConstrainToDirection(WorldDirection) * (1.0 + ConstrainBounce);
			}

			SpringOffset = SpringOffset.GetClampedToMaxSize(CircleRadius);

			// Move the component to where we're clamped
			CurrentPhysicsLocation = AttachTransform.TransformPosition(SpringParentOffset + SpringOffset);
		}
	}

	/**
	 * If we have completely disabled an axis (through constraints), we want to filter that away from all forces :)
	 * That way we dont have to worry about keeping us constrained within that point
	 */
	private void ApplyLockedConstraints(FVector& Vec) const
	{
		if(CircleRadius < KINDA_SMALL_NUMBER)
			Vec = FVector::ZeroVector;
		else
			Vec = Vec.ConstrainToPlane(GetWorldConstrainAxis(GetCircleConstraintNormalVector()));
	}

	FVector GetWorldLocationAfterConstraints(FVector InWorldLocation) const
	{
		const FVector RelativeNormal = GetRelativeConstrainAxis(GetCircleConstraintNormalVector());

		FTransform AttachTransform = FTransform::Identity;
		if (AttachParent != nullptr)
			AttachTransform = AttachParent.WorldTransform;

		const FVector RelativePosition = AttachTransform.InverseTransformPosition(InWorldLocation);

		FVector SpringOffset = RelativePosition - SpringParentOffset;

		// Project on to the circle normal
		SpringOffset = SpringOffset.VectorPlaneProject(RelativeNormal);
		SpringOffset = SpringOffset.GetClampedToMaxSize(CircleRadius);
	
		return AttachTransform.TransformPosition(SpringParentOffset + SpringOffset);
	}

	FVector GetRelativeConstrainAxis(FVector Axis) const
	{
		return RelativeTransform.TransformVectorNoScale(Axis);
	}

	FVector GetWorldConstrainAxis(FVector Axis) const
	{
		return WorldTransform.TransformVectorNoScale(Axis);
	}

	FVector GetCircleConstraintNormalVector() const
	{
		switch(CircleNormal)
		{
			case EFauxPhysicsTranslateCircleConstraintNormal::Forward:
				return FVector::ForwardVector;

			case EFauxPhysicsTranslateCircleConstraintNormal::Right:
				return FVector::RightVector;

			case EFauxPhysicsTranslateCircleConstraintNormal::Up:
				return FVector::UpVector;
		}
	}
}

#if EDITOR
class UFauxPhysicsCircleTranslateComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UFauxPhysicsCircleTranslateComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		UFauxPhysicsCircleTranslateComponent TranslateComponent = Cast<UFauxPhysicsCircleTranslateComponent>(Component);

		FVector Origin = TranslateComponent.GetRelativeLocation();
		if(Editor::IsPlaying())
		{
			if(TranslateComponent.AttachParent != nullptr)
				Origin = TranslateComponent.SpringParentOffset;
		}

		FTransform AttachTransform;
		if (TranslateComponent.AttachParent != nullptr)
		{
			Origin = TranslateComponent.AttachParent.WorldTransform.TransformPosition(Origin);
			AttachTransform = TranslateComponent.AttachParent.WorldTransform;
		}

		const FVector Normal = TranslateComponent.GetWorldConstrainAxis(TranslateComponent.GetCircleConstraintNormalVector());

		FLinearColor Color;
		switch(TranslateComponent.CircleNormal)
		{
			case EFauxPhysicsTranslateCircleConstraintNormal::Forward:
				Color = FLinearColor::Red;
				break;

			case EFauxPhysicsTranslateCircleConstraintNormal::Right:
				Color = FLinearColor::Green;
				break;

			case EFauxPhysicsTranslateCircleConstraintNormal::Up:
				Color = FLinearColor::Blue;
				break;
		}

		DrawCircleNormal(Origin, Normal, Color);
		DrawCircleConstraint(Origin, Normal, Color, TranslateComponent.CircleRadius);
	}

	private void DrawCircleNormal(FVector Location, FVector UpAxis, FLinearColor Color)
	{
		DrawArrow(Location, Location + UpAxis * 100, Color, 10, 5.0);
	}

	private void DrawCircleConstraint(FVector Location, FVector UpAxis, FLinearColor Color, float Radius)
	{
		DrawArrow(Location, Location + UpAxis * 100, Color, 10, 5.0);
		const int Segments = Math::Min(10 + Math::CeilToInt(Radius / 20), 64);
		DrawCircle(Location, Radius, Color, 5.0, UpAxis, Segments);
	}
}
#endif