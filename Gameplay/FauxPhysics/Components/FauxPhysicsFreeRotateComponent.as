enum EFauxPhysicsFreeRotateNetworkMode
{
	// Position is not networked, but simulated fully locally
	Local,
	// Position is synced from the actor's control side that owns the faux physics component
	SyncedFromActorControl,
	// Position is synced always from Mio's side
	SyncedFromMioControl,
	// Position is synced always from Zoe's side
	SyncedFromZoeControl,
	/**
	 * Rotation is independently calculated on both sides, and then interpolated to slowly reduce the error between them.
	 * OBS! This changes physics behavior compared to local, as the interpolation makes the physics forces a bit smaller!
	 * 	    The higher the ping, the bigger the error in the physics.
	 * OBS! Impact delegates still happen independently on both sides, and are not synced!
	 */
	TwoWaySynced,
};

UCLASS(ClassGroup = FauxPhysics, Meta = (HideCategories = "LOD Physics AssetUserData Collision Tags Cooking Activation Rendering"))
class UFauxPhysicsFreeRotateComponent : UFauxPhysicsComponentBase
{
	access EditAndReadOnly = private, * (editdefaults, readonly);

	FVector AngularVelocity;
	FVector PendingForces;

	FQuat CurrentRotation;
	FQuat LocalOriginRotation;

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	float Friction = 2.4;

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	float ForceScalar = 1.0;

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	float SpringStrength = 0.0;

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	float ConstrainedAngularVelocityDegrees = 0.0;
	private float ConstrainedAngularVelocityRad = 0.0;

	// Bounds used for calculating torque, essentially acts as an inverse force scalar
	UPROPERTY(Category = FauxPhysics, EditAnywhere, AdvancedDisplay)
	float TorqueBounds = 100.0;

	UPROPERTY(EditAnywhere, Category = "Network")
	access:EditAndReadOnly
	EFauxPhysicsFreeRotateNetworkMode NetworkMode = EFauxPhysicsFreeRotateNetworkMode::Local;

	UHazeCrumbSyncedRotatorComponent SyncedRotation;
	UHazeTwoWaySyncedRotatorComponent SyncedTwoWayRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (NetworkMode != EFauxPhysicsFreeRotateNetworkMode::Local && Network::IsGameNetworked())
		{
			if (NetworkMode != EFauxPhysicsFreeRotateNetworkMode::TwoWaySynced)
			{
				SyncedRotation = UHazeCrumbSyncedRotatorComponent::Create(Owner, FName(GetName() + "_Rotation"));
				switch (NetworkMode)
				{
					case EFauxPhysicsFreeRotateNetworkMode::SyncedFromMioControl:
						SyncedRotation.OverrideControlSide(Game::Mio);
					break;
					case EFauxPhysicsFreeRotateNetworkMode::SyncedFromZoeControl:
						SyncedRotation.OverrideControlSide(Game::Zoe);
					break;
					default:
					break;
				}
				SyncedRotation.OnWake.AddUFunction(this, n"OnSyncWake");
			}
			else
			{
				SyncedTwoWayRotation = UHazeTwoWaySyncedRotatorComponent::Create(Owner, FName(GetName() + "_Rotation"));
				SyncedTwoWayRotation.OnWake.AddUFunction(this, n"OnSyncWake");
			}
		}

		LocalOriginRotation = GetRelativeTransform().Rotation;
		ConstrainedAngularVelocityRad = Math::DegreesToRadians(ConstrainedAngularVelocityDegrees);
	}

	bool HasFauxPhysicsControl() const override
	{
		if (SyncedRotation != nullptr)
			return SyncedRotation.HasControl();
		return true;
	}

	void ApplyForce(FVector Origin, FVector Force) override
	{
		if (!IsEnabled())
			return;

		PendingForces += FauxPhysics::Calculation::LinearToAngular(WorldLocation, TorqueBounds, Origin, Force) * ForceScalar;
		Wake();
	}

	void ApplyImpulse(FVector Origin, FVector Impulse) override
	{
		if (!IsEnabled())
			return;

		AngularVelocity += FauxPhysics::Calculation::LinearToAngular(WorldLocation, TorqueBounds, Origin, Impulse) * ForceScalar;
		Wake();
	}

	void ApplyMovement(FVector Origin, FVector Movement) override
	{
		if (!IsEnabled())
			return;

		FVector AngularMovement = FauxPhysics::Calculation::LinearToAngular(WorldLocation, TorqueBounds, Origin, Movement);
		FQuat DeltaQuat = FauxPhysics::Calculation::VecToQuat(AngularMovement);
		CurrentRotation = DeltaQuat * CurrentRotation;

		if(HasFauxPhysicsControl())
			ControlUpdateSyncedPosition();

		Wake();
	}

	FQuat GetOriginWorldSpace() property
	{
		if (AttachParent != nullptr)
			return AttachParent.WorldTransform.Rotation * LocalOriginRotation;
		else
			return LocalOriginRotation;
	}

	bool UpdateFauxPhysics(float InOriginalDeltaTime) override
	{
		if (SyncedTwoWayRotation != nullptr)
			CurrentRotation = SyncedTwoWayRotation.Value.Quaternion();

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
			if (SpringStrength > SMALL_NUMBER && CurrentRotation.Angle > KINDA_SMALL_NUMBER)
				return false;

			// Don't sleep while moving
			if (!PendingForces.IsNearlyZero())
				return false;
			if (!AngularVelocity.IsNearlyZero())
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
			if (!SyncedRotation.Value.Quaternion().Equals(CurrentRotation))
				return false;
		}

		return true;
	}

	protected void PhysicsStep(float DeltaTime) override
	{
		// Spring
		if (SpringStrength > SMALL_NUMBER)
			AngularVelocity -= FauxPhysics::Calculation::QuatToVec(CurrentRotation) * SpringStrength * DeltaTime;

		AngularVelocity += PendingForces * DeltaTime;
		AngularVelocity = FauxPhysics::Calculation::ApplyFriction(AngularVelocity, Friction, DeltaTime);

		if (ConstrainedAngularVelocityRad > KINDA_SMALL_NUMBER)
			AngularVelocity = AngularVelocity.GetClampedToSize(-ConstrainedAngularVelocityRad, ConstrainedAngularVelocityRad);

		FQuat DeltaQuat = FauxPhysics::Calculation::VecToQuat(AngularVelocity * DeltaTime);
		CurrentRotation = DeltaQuat * CurrentRotation;
	}

	protected void ControlUpdateSyncedPosition() override
	{
		check(HasFauxPhysicsControl());

		SetWorldRotation(CurrentRotation * OriginWorldSpace);

		if (SyncedRotation != nullptr)
			SyncedRotation.Value = CurrentRotation.Rotator();
		else if (SyncedTwoWayRotation != nullptr)
			SyncedTwoWayRotation.Value = CurrentRotation.Rotator();
	}

	protected void RemoteUpdateSyncedPosition() override
	{
		if (SyncedRotation == nullptr)
			return;

		check(!HasFauxPhysicsControl());

		CurrentRotation = SyncedRotation.Value.Quaternion();
		SetWorldRotation(CurrentRotation * OriginWorldSpace);
	}

	void ResetForces() override
	{
		PendingForces = FVector::ZeroVector;
	}

	void ResetPhysics() override
	{
		AngularVelocity = FVector::ZeroVector;
	}

	void ResetInternalState() override
	{
		Super::ResetInternalState();
		
		CurrentRotation = FQuat::Identity;
	}
}

class UFauxPhysicsFreeRotateComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UFauxPhysicsFreeRotateComponent;
	const float Radius = 250.0;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		if(!Editor::IsComponentSelected(Component) && !Component.World.IsPreviewWorld())
			return;

		auto RotateComponent = Cast<UFauxPhysicsFreeRotateComponent>(Component);
		FQuat Origin = RotateComponent.OriginWorldSpace;

		{
			DrawRotationAxis(RotateComponent.WorldLocation, Origin.ForwardVector, Origin.UpVector, 300.0, FLinearColor::Red);
			DrawAxisLine(RotateComponent.WorldLocation, RotateComponent.UpVector, FLinearColor::Red);
		}
		{
			DrawRotationAxis(RotateComponent.WorldLocation, Origin.RightVector, Origin.ForwardVector, 300.0, FLinearColor::Green);
			DrawAxisLine(RotateComponent.WorldLocation, RotateComponent.ForwardVector, FLinearColor::Green);
		}
		{
			DrawRotationAxis(RotateComponent.WorldLocation, Origin.UpVector, Origin.RightVector, 300.0, FLinearColor::Blue);
			DrawAxisLine(RotateComponent.WorldLocation, RotateComponent.RightVector, FLinearColor::Blue);
		}

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

	void DrawRotationAxis(FVector Location, FVector Axis, FVector Perpendicular, float Angle, FLinearColor Color)
	{
		bool bIsCapped = Angle < 160.0;
		float CappedAngle = Math::Min(Angle, 160.0);

		DrawArc(Location, CappedAngle * 2.0, Radius, Perpendicular, Color, 5.0, Normal = Axis, Segments = 32, bDrawSides = false);

		// Arrows to show uncapped rotation
		FQuat CapStartQuat = FQuat(Axis, Math::DegreesToRadians(CappedAngle));
		FQuat CapEndQuat = FQuat(Axis, Math::DegreesToRadians(CappedAngle + 5.0));

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
