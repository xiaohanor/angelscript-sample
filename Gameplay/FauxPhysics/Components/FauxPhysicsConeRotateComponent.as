enum EFauxPhysicsConeRotateNetworkMode
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

event void FFauxPhysicsConeRotateConstraintHit(float Strength);

UCLASS(ClassGroup = FauxPhysics, Meta = (HideCategories = "LOD Physics AssetUserData Collision Tags Cooking Activation Rendering"))
class UFauxPhysicsConeRotateComponent : UFauxPhysicsComponentBase
{
	access EditAndReadOnly = private, * (editdefaults, readonly);

	FVector AngularVelocity;
	FVector PendingForces;
	FVector PendingImpulses;

	FQuat CurrentRotation;
	FQuat OriginRotation;

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	float Friction = 2.4;

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	float ForceScalar = 1.0;

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	float SpringStrength = 0.0;

	UPROPERTY(Category = Cone, EditAnywhere)
	float ConeAngle = 40.0;

	// Bounds used for calculating torque, essentially acts as an inverse force scalar
	UPROPERTY(Category = FauxPhysics, EditAnywhere, AdvancedDisplay)
	float TorqueBounds = 100.0;

	UPROPERTY(Category = Cone, EditAnywhere)
	FVector LocalConeDirection = FVector::UpVector;

	UPROPERTY(Category = Cone, EditAnywhere)
	float ConstrainBounce = 0.5;

	UPROPERTY(Category = Cone, EditAnywhere)
	bool bConstrainTwist = false;

	// Minimum strength to hit the constraint before an impact event is sent
	UPROPERTY(EditAnywhere, Category = "Impacts")
	float ImpactMinStrength = 0.5;

	// Minimum interval between impacts being registered
	UPROPERTY(EditAnywhere, Category = "Impacts")
	float MinTimeBetweenImpacts = 0.5;

	UPROPERTY(EditAnywhere, Category = "Network")
	access:EditAndReadOnly
	EFauxPhysicsConeRotateNetworkMode NetworkMode = EFauxPhysicsConeRotateNetworkMode::Local;

	UHazeCrumbSyncedRotatorComponent SyncedRotation;
	UHazeTwoWaySyncedRotatorComponent SyncedTwoWayRotation;

	// The "Strength" given in this event is ANGULAR VELOCITY
	// So remember that it might be much smaller than one expects
	UPROPERTY()
	FFauxPhysicsConeRotateConstraintHit OnConstraintHit;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (NetworkMode != EFauxPhysicsConeRotateNetworkMode::Local && Network::IsGameNetworked())
		{
			if (NetworkMode != EFauxPhysicsConeRotateNetworkMode::TwoWaySynced)
			{
				SyncedRotation = UHazeCrumbSyncedRotatorComponent::Create(Owner, FName(GetName() + "_Rotation"));
				switch (NetworkMode)
				{
					case EFauxPhysicsConeRotateNetworkMode::SyncedFromMioControl:
						SyncedRotation.OverrideControlSide(Game::Mio);
					break;
					case EFauxPhysicsConeRotateNetworkMode::SyncedFromZoeControl:
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

			devCheck(MinTimeBetweenImpacts >= 0.1, f"FauxPhysics component {this} on {Owner} is networked but MinTimeBetweenImpacts is set to {MinTimeBetweenImpacts}, increase minimum time to prevent network spam.");
		}

		OriginRotation = RelativeTransform.Rotation;
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

	void ApplyForce(FVector Origin, FVector Force) override
	{
		if (!IsEnabled())
			return;

		FVector AngularForce = FauxPhysics::Calculation::LinearToAngular(WorldLocation, TorqueBounds, Origin, Force);

		// Cant rotate around the cone direction
		AngularForce = AngularForce.ConstrainToPlane(GetConeDirectionWorldSpace());

		if (!AngularForce.IsNearlyZero())
		{
			PendingForces += AngularForce * ForceScalar;
			Wake();
		}
	}

	void ApplyImpulse(FVector Origin, FVector Impulse) override
	{
		if (!IsEnabled())
			return;

		FVector AngularImpulse = FauxPhysics::Calculation::LinearToAngular(WorldLocation, TorqueBounds, Origin, Impulse);

		// Cant rotate around the cone direction
		AngularImpulse = AngularImpulse.ConstrainToPlane(GetConeDirectionWorldSpace());

		if (!AngularImpulse.IsNearlyZero())
		{
			AngularVelocity += AngularImpulse * ForceScalar;
			Wake();
		}
	}

	void ApplyMovement(FVector Origin, FVector Movement) override
	{
		if (!IsEnabled())
			return;

		FVector AngularMovement = FauxPhysics::Calculation::LinearToAngular(WorldLocation, TorqueBounds, Origin, Movement);

		// Cant rotate around the cone direction
		AngularMovement = AngularMovement.ConstrainToPlane(GetConeDirectionWorldSpace());
		ApplyDeltaRotation(FauxPhysics::Calculation::VecToQuat(AngularMovement));

		if(HasFauxPhysicsControl())
			ControlUpdateSyncedPosition();

		Wake();
	}

	FQuat GetOriginWorldSpace()
	{
		if (AttachParent != nullptr)
			return AttachParent.WorldTransform.Rotation * OriginRotation;
		else
			return OriginRotation;
	}

	FVector GetConeDirectionWorldSpace()
	{
		return (OriginRotation * LocalConeDirection).GetSafeNormal();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float InOriginalDeltaTime)
	{
		if (SyncedTwoWayRotation != nullptr)
			CurrentRotation = SyncedTwoWayRotation.Value.Quaternion();

		Super::Tick(InOriginalDeltaTime);
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
			if (!PendingImpulses.IsNearlyZero())
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
		bool bZeroRotation = Math::Abs(CurrentRotation.Angle) < 0.001;
		if (SpringStrength > SMALL_NUMBER)
		{
			if (!bZeroRotation)
				AngularVelocity -= FauxPhysics::Calculation::QuatToVec(CurrentRotation) * SpringStrength;
			else if (AngularVelocity.SizeSquared() < 0.0001)
				CurrentRotation = FQuat();
		}

		AngularVelocity += PendingForces * DeltaTime;
		AngularVelocity += PendingImpulses;
		AngularVelocity = FauxPhysics::Calculation::ApplyFriction(AngularVelocity, Friction, DeltaTime);

		FQuat DeltaQuat = FauxPhysics::Calculation::VecToQuat(AngularVelocity * DeltaTime);
		ApplyDeltaRotation(DeltaQuat);
	}

	protected void ControlUpdateSyncedPosition() override
	{
		check(HasFauxPhysicsControl());
		
		SetWorldRotation(CurrentRotation * GetOriginWorldSpace());

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
		SetWorldRotation(CurrentRotation * GetOriginWorldSpace());

		// Trigger impacts the control side sent to us
		float TrailTime = SyncedRotation.GetCrumbTrailReceiveTime();
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

	void ApplyDeltaRotation(FQuat DeltaQuat)
	{
		CurrentRotation = DeltaQuat * CurrentRotation;

		// Constrain to the cone
		bool bZeroRotation = CurrentRotation.Angle < KINDA_SMALL_NUMBER;
		if (!bZeroRotation)
		{
			FVector RotationVec = FauxPhysics::Calculation::QuatToVec(CurrentRotation);

			const FVector ConeDirectionWorldSpace = GetConeDirectionWorldSpace();

			// Re-constrain to cone axis here (for safety)
			RotationVec = RotationVec.ConstrainToPlane(ConeDirectionWorldSpace).GetSafeNormal() * RotationVec.Size();

			// Clamp length of rotation, effectively limiting the rotation to a cone
			float ConeAngleRad = Math::DegreesToRadians(ConeAngle);
			float RotationAngle = RotationVec.SizeSquared();
			if (RotationAngle > Math::Square(ConeAngleRad))
			{
				TriggerImpact(AngularVelocity.Size());

				FVector CollisionRotationNormal = RotationVec.SafeNormal;

				if (CollisionRotationNormal.DotProduct(AngularVelocity) > 0.0)
				{
					// Bounce our velocity!
					// However, we only want to "bounce" the part that is actually taking us
					// 	into the boundary

					FVector BounceVelocityPart = AngularVelocity.ConstrainToDirection(CollisionRotationNormal);
					AngularVelocity -= BounceVelocityPart * (1.0 + ConstrainBounce);
				}

				FVector ClampedRotation = CollisionRotationNormal * ConeAngleRad;
				CurrentRotation = FauxPhysics::Calculation::VecToQuat_Precise(ClampedRotation);
			}

			if(bConstrainTwist)
			{
				// Un-twist the current rotation, making sure that our vertical axis always has (almost) 0 angle
				// Not sure if we need to normalize or not, it seems to work well without normalizing
				//CurrentRotation.Normalize();
				const float TwistAngle = CurrentRotation.GetTwistAngle(ConeDirectionWorldSpace);
				CurrentRotation = FQuat(ConeDirectionWorldSpace, -TwistAngle) * CurrentRotation;
			}
		}
	}

	void ResetForces() override
	{
		PendingForces = PendingImpulses = FVector::ZeroVector;
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

	private TArray<FFauxPhysicsConeRotateImpact> QueuedImpacts;
	private float IgnoreImpactsUntil = 0.0;

	private void TriggerImpact(float Strength)
	{
		if (Strength < ImpactMinStrength)
			return;
		if (Time::GameTimeSeconds < IgnoreImpactsUntil)
			return;

		IgnoreImpactsUntil = Time::GameTimeSeconds + MinTimeBetweenImpacts;

		OnConstraintHit.Broadcast(Strength);

		if (SyncedRotation != nullptr && HasFauxPhysicsControl() && FauxPhysics::Calculation::CVar_DropAllRemoteImpacts.GetInt() == 0)
		{
			if (OnConstraintHit.IsBound())
			{
				NetSendImpact(
					SyncedRotation.GetCrumbTrailSendTime(),
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

		FFauxPhysicsConeRotateImpact Impact;
		Impact.CrumbTrailTime = CrumbTrailTime;
		Impact.Strength = Strength;
		QueuedImpacts.Add(Impact);
	}
}

struct FFauxPhysicsConeRotateImpact
{
	float CrumbTrailTime;
	float Strength;
}

class UFauxPhysicsConeRotateComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UFauxPhysicsConeRotateComponent;
	const float Radius = 250.0;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto RotateComponent = Cast<UFauxPhysicsConeRotateComponent>(Component);
		FQuat Origin = RotateComponent.GetOriginWorldSpace();
		FQuat Current = RotateComponent.ComponentQuat;

		FVector NormalizedConeDirection = RotateComponent.LocalConeDirection.SafeNormal;

		if (Component.World.IsGameWorld())
		{
			DrawCone(RotateComponent.WorldLocation, Origin * NormalizedConeDirection, RotateComponent.ConeAngle);
			DrawAxisLine(RotateComponent.WorldLocation, Current * NormalizedConeDirection, FLinearColor::Blue);
		}
		else
		{
			DrawCone(RotateComponent.WorldLocation, Current * NormalizedConeDirection, RotateComponent.ConeAngle);
			DrawAxisLine(RotateComponent.WorldLocation, Current * NormalizedConeDirection, FLinearColor::Blue);
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

	void DrawCone(FVector Origin, FVector Direction, float ConeAngle)
	{
		float ConeRadians = Math::DegreesToRadians(ConeAngle);

		// Construct perpendicular vector
		FVector P1 = Direction.CrossProduct(Direction.GetAbs().Equals(FVector::UpVector) ? FVector::RightVector : FVector::UpVector);
		P1.Normalize();

		FVector P2 = P1.CrossProduct(Direction);

		// Draw cone sides
		FVector Tip = Direction * Radius;
		FVector TiltedTip = FQuat(P1, ConeRadians) * Tip;
		FVector ConeBase = Direction * Math::Cos(ConeRadians) * Radius;

		float StepRadians = TWO_PI / 10;

		for(int i = 0; i < 10; ++i)
		{
			float Angle = i * StepRadians;
			FVector StepTip = FQuat(Direction, Angle) * TiltedTip;

			DrawDashedLine(Origin, Origin + StepTip, FLinearColor::Gray);
		}

		// Draw tip circle
		DrawCircle(Origin + ConeBase, Math::Sin(ConeRadians) * Radius, FLinearColor::Yellow, 2.0, Direction);

		// Draw rotational arcs
		DrawArc(Origin, ConeAngle * 2.0, Radius, Direction, FLinearColor::Yellow, 2.0, P1, bDrawSides = false);
		DrawArc(Origin, ConeAngle * 2.0, Radius, Direction, FLinearColor::Yellow, 2.0, P2, bDrawSides = false);
	}

	void DrawAxisLine(FVector Origin, FVector Direction, FLinearColor Color)
	{
		FVector Tip = Direction * Radius;

		DrawLine(Origin, Origin + Tip, Color, 3.0);
		DrawWireSphere(Origin + Tip, 5.0, Color);
	}
}