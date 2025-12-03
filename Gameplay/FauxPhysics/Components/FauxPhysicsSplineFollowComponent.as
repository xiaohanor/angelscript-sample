event void FFauxPhysicsSplineFollowConstraintHit(float Strength);

enum EFauxPhysicsSplineFollowNetworkMode
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

UCLASS(ClassGroup = FauxPhysics, Meta = (HideCategories = "LOD Physics AssetUserData Collision Tags Cooking Activation Rendering"))
class UFauxPhysicsSplineFollowComponent : UFauxPhysicsComponentBase
{
	access EditAndReadOnly = private, * (editdefaults, readonly);

	UPROPERTY(Category = Spline, EditAnywhere)
	AActor InitialSplineActor;

	UPROPERTY(Category = Spline, EditAnywhere)
	bool bFollowRotation = true;

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	float Friction = 2.4;

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	float ForceScalar = 1.0;

	UPROPERTY(Category = FauxPhysics, EditAnywhere)
	float SplineBoundBounce = 0.5;

	// Minimum strength to hit the constraint before an impact event is sent
	UPROPERTY(EditAnywhere, Category = "Impacts")
	float ImpactMinStrength = 10.0;

	// Minimum interval between impacts being registered
	UPROPERTY(EditAnywhere, Category = "Impacts")
	float MinTimeBetweenImpacts = 0.5;

	UPROPERTY(EditAnywhere, Category = "Network")
	access:EditAndReadOnly
	EFauxPhysicsSplineFollowNetworkMode NetworkMode = EFauxPhysicsSplineFollowNetworkMode::Local;

	UPROPERTY()
	FFauxPhysicsSplineFollowConstraintHit OnStartHit;
	UPROPERTY()
	FFauxPhysicsSplineFollowConstraintHit OnEndHit;

	private UHazeCrumbSyncedSplinePositionComponent SyncedPosition;
	private UHazeTwoWaySyncedFloatComponent SyncedTwoWaySplineDistance; 

	FSplinePosition SplinePosition;
	float Velocity = 0.0;

	float PendingForces = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (NetworkMode != EFauxPhysicsSplineFollowNetworkMode::Local && Network::IsGameNetworked())
		{
			if (NetworkMode != EFauxPhysicsSplineFollowNetworkMode::TwoWaySynced)
			{
				SyncedPosition = UHazeCrumbSyncedSplinePositionComponent::Create(Owner, FName(GetName() + "_Position"));
				switch (NetworkMode)
				{
					case EFauxPhysicsSplineFollowNetworkMode::SyncedFromMioControl:
						SyncedPosition.OverrideControlSide(Game::Mio);
					break;
					case EFauxPhysicsSplineFollowNetworkMode::SyncedFromZoeControl:
						SyncedPosition.OverrideControlSide(Game::Zoe);
					break;
					default:
					break;
				}
				SyncedPosition.OnWake.AddUFunction(this, n"OnSyncWake");
			}
			else
			{
				SyncedTwoWaySplineDistance = UHazeTwoWaySyncedFloatComponent::Create(Owner, FName(GetName() + "_POSITION"));
				SyncedTwoWaySplineDistance.OnWake.AddUFunction(this, n"OnSyncWake");
			}
			devCheck(MinTimeBetweenImpacts >= 0.1, f"FauxPhysics component {this} on {Owner} is networked but MinTimeBetweenImpacts is set to {MinTimeBetweenImpacts}, increase minimum time to prevent network spam.");
		}

		if (InitialSplineActor != nullptr)
		{
			auto Spline = Spline::GetGameplaySpline(InitialSplineActor, this);
			if (Spline == nullptr)
			{
				#if EDITOR
				devError(f"Faux SplineFollowComponent on '{Owner.ActorLabel}' had an InitialSplineActor '{InitialSplineActor.ActorLabel}' with no spline component");
				#else
				devError(f"Faux SplineFollowComponent on '{Owner.Name}' had an InitialSplineActor '{InitialSplineActor.Name}' with no spline component");
				#endif
				return;
			}

			SetSplineToFollow(Spline);
		}
		else
		{
			// See if we have a spline as a parent
			auto Parent = AttachParent;
			while(Parent != nullptr)
			{
				auto Spline = Cast<UHazeSplineComponent>(Parent);
				if (Spline != nullptr)
				{
					CookChecks::EnsureSplineCanBeUsedOutsideEditor(this, Spline, bRetrievedFromActor = false);
					SetSplineToFollow(Spline);
					break;
				}

				Parent = Parent.AttachParent;
			}
		}
	}

	void OverrideNetworkSyncRate(EHazeCrumbSyncRate SyncRate) override
	{
		if (SyncedPosition != nullptr)
			SyncedPosition.OverrideSyncRate(SyncRate);
		if (SyncedTwoWaySplineDistance != nullptr)
			SyncedTwoWaySplineDistance.OverrideSyncRate(SyncRate);
	}

	bool HasFauxPhysicsControl() const override
	{
		if (SyncedPosition != nullptr)
			return SyncedPosition.HasControl();
		return true;
	}

	#if EDITOR
	UFUNCTION(CallInEditor)
	private void SnapToSpline()
	{
		check(!Editor::IsPlaying());

		if (InitialSplineActor == nullptr)
			return;

		auto Spline = UHazeSplineComponent::Get(InitialSplineActor);
		if (Spline == nullptr)
			return;

		auto Transform = Spline.GetClosestSplineWorldTransformToWorldLocation(GetWorldLocation());
		SetWorldLocation(Transform.Location);
		if (bFollowRotation)
			SetWorldRotation(Transform.Rotation);

		Wake();
	}
	#endif

	UFUNCTION()
	void SetSplineToFollow(UHazeSplineComponent NewSpline)
	{
		if (NewSpline == nullptr)
		{
			DetachFromSpline();
			return;
		}

		SplinePosition = NewSpline.GetClosestSplinePositionToWorldLocation(GetWorldLocation());
		AttachToComponent(NewSpline, NAME_None, EAttachmentRule::KeepWorld);

		if(HasFauxPhysicsControl())
		{
			ControlUpdateSyncedPosition();
		}
		else
		{
			if (SyncedPosition != nullptr)
				SyncedPosition.Value = SplinePosition;
			RemoteUpdateSyncedPosition();
		}

		Wake();
	}

	UFUNCTION()
	void DetachFromSpline()
	{
		DetachFromParent(true);
		SplinePosition = FSplinePosition();

		Wake();
	}

	void ApplyForce(FVector Origin, FVector Force) override
	{
		if (!IsEnabled())
			return;

		PendingForces += SplinePosition.WorldForwardVector.DotProduct(Force) * ForceScalar;

		Wake();
	}

	void ApplyImpulse(FVector Origin, FVector Impulse) override
	{
		if (!IsEnabled())
			return;

		Velocity += SplinePosition.WorldForwardVector.DotProduct(Impulse) * ForceScalar;

		Wake();
	}

	void ApplyMovement(FVector Origin, FVector Movement) override
	{
		if (!IsEnabled())
			return;

		float SplineMovement = SplinePosition.WorldForwardVector.DotProduct(Movement);
		ApplyMoveDelta(SplineMovement);

		if(HasFauxPhysicsControl())
			ControlUpdateSyncedPosition();

		Wake();
	}

	/**
	 * Map the current position to alpha values between 0 and 1,
	 * where 0 indicates the start of the spline and 1 indicates the end of the spline.
	 */
	UFUNCTION(BlueprintPure)
	float GetCurrentAlphaBetweenConstraints() const
	{
		if (SplinePosition.CurrentSpline == nullptr)
			return 0.0;
		float SplineLength = SplinePosition.CurrentSpline.SplineLength;
		if (SplineLength == 0.0)
			return 0.0;
		return SplinePosition.CurrentSplineDistance / SplineLength;
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
			// Don't sleep while moving
			if (!Math::IsNearlyZero(PendingForces))
				return false;
			if (!Math::IsNearlyZero(Velocity))
				return false;

			if (SyncedTwoWaySplineDistance != nullptr)
			{
				if (!SyncedTwoWaySplineDistance.IsSleeping())
					return false;
			}
		}
		else
		{
			if (!SyncedPosition.IsSleeping())
				return false;
			if (SyncedPosition.Value.CurrentSpline != SplinePosition.CurrentSpline)
				return false;
			if (SyncedPosition.Value.CurrentSplineDistance != SplinePosition.CurrentSplineDistance)
				return false;
		}

		return true;
	}

	protected void PhysicsStep(float DeltaTime) override
	{
		if (!SplinePosition.IsValid())
		{
			Velocity = PendingForces = 0.0;
			return;
		}

		Velocity += PendingForces * DeltaTime;
		Velocity = FauxPhysics::Calculation::ApplyFriction(Velocity, Friction, DeltaTime);
		ApplyMoveDelta(Velocity * DeltaTime);
	}

	protected void ControlUpdateSyncedPosition() override
	{
		check(HasFauxPhysicsControl());

		if (bFollowRotation)
			SetRelativeLocationAndRotation(SplinePosition.RelativeLocation, SplinePosition.RelativeRotation);
		else
			SetRelativeLocation(SplinePosition.RelativeLocation);

		if (SyncedPosition != nullptr)
			SyncedPosition.Value = SplinePosition;
		else if (SyncedTwoWaySplineDistance != nullptr)
			SyncedTwoWaySplineDistance.Value = SplinePosition.GetCurrentSplineDistance();
	}

	protected void RemoteUpdateSyncedPosition() override
	{
		if (SyncedPosition == nullptr)
			return;

		check(!HasFauxPhysicsControl());

		SplinePosition = SyncedPosition.Value;
		if (!SplinePosition.IsValid())
			return;

		if (bFollowRotation)
			SetRelativeLocationAndRotation(SplinePosition.RelativeLocation, SplinePosition.RelativeRotation);
		else
			SetRelativeLocation(SplinePosition.RelativeLocation);

		// Trigger impacts the control side sent to us
		float TrailTime = SyncedPosition.GetCrumbTrailReceiveTime();
		for (int i = QueuedImpacts.Num() - 1; i >= 0; --i)
		{
			// Impact hasn't been reached yet
			auto& QueuedImpact = QueuedImpacts[i];
			if (QueuedImpact.CrumbTrailTime > TrailTime)
				continue;

			// Apply the impact
			if (QueuedImpact.bStartImpact)
				OnStartHit.Broadcast(QueuedImpact.Strength);
			else
				OnEndHit.Broadcast(QueuedImpact.Strength);
			QueuedImpacts.RemoveAtSwap(i);
		}
	}

	bool UpdateFauxPhysics(float InOriginalDeltaTime) override
	{
		if (SyncedTwoWaySplineDistance != nullptr)
		{
			SplinePosition = FSplinePosition(
				SplinePosition.GetCurrentSpline(),
				SyncedTwoWaySplineDistance.Value,
				SplinePosition.IsForwardOnSpline(),
			);
		}

		return Super::UpdateFauxPhysics(InOriginalDeltaTime);
	}

	void ApplyMoveDelta(float Delta)
	{
		float RemainingDistance = 0;
		bool bMoveSuccess = SplinePosition.Move(Delta, RemainingDistance);
		// Uh oh! We hit a spline boundary. Rebound.
		if (!bMoveSuccess)
		{
			// A _bit_ of assumption here, but if we have a positive speed
			//	we're gonna assume we hit the end, and vice versa
			TriggerImpact(Velocity < 0.0, Math::Abs(Velocity));
			Velocity -= Velocity * (1.0 + SplineBoundBounce);

			// Move back the remaining distance we bounced
			SplinePosition.Move(-RemainingDistance * SplineBoundBounce);
		}
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
		SplinePosition = SplinePosition.CurrentSpline.GetClosestSplinePositionToWorldLocation(GetWorldLocation());
	}

	private TArray<FFauxPhysicsSplineFollowImpact> QueuedImpacts;
	private float IgnoreImpactsUntil = 0.0;

	private void TriggerImpact(bool bStartImpact, float Strength)
	{
		if (Strength < ImpactMinStrength)
			return;
		if (Time::GameTimeSeconds < IgnoreImpactsUntil)
			return;

		IgnoreImpactsUntil = Time::GameTimeSeconds + MinTimeBetweenImpacts;

		if (bStartImpact)
			OnStartHit.Broadcast(Strength);
		else
			OnEndHit.Broadcast(Strength);

		if (SyncedPosition != nullptr && HasFauxPhysicsControl() && FauxPhysics::Calculation::CVar_DropAllRemoteImpacts.GetInt() == 0)
		{
			if (bStartImpact ? OnStartHit.IsBound() : OnEndHit.IsBound())
			{
				NetSendImpact(
					SyncedPosition.GetCrumbTrailSendTime(),
					bStartImpact,
					Strength
				);
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetSendImpact(float CrumbTrailTime, bool bStartImpact, float Strength)
	{
		if (HasFauxPhysicsControl())
			return;

		FFauxPhysicsSplineFollowImpact Impact;
		Impact.CrumbTrailTime = CrumbTrailTime;
		Impact.bStartImpact = bStartImpact;
		Impact.Strength = Strength;
		QueuedImpacts.Add(Impact);
	}
}

struct FFauxPhysicsSplineFollowImpact
{
	float CrumbTrailTime;
	float Strength;
	bool bStartImpact;
}