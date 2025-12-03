struct FAdultTailDragonHomingTailSmashActivateParams
{
	USceneComponent TargetComp;
}

class UAdultDragonHomingTailSmashSpinCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonHomingTailSmash::Tags::AdultDragonTailSmash);

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 10;

	UAdultDragonHomingTailSmashComponent SmashComp;
	UPlayerMovementComponent MoveComp;
	UPlayerTailAdultDragonComponent DragonComp;
	UPlayerAimingComponent AimComp;
	AAdultDragonBoundarySpline BoundarySpline;

	USimpleMovementData Movement;
	UAdultDragonTailSmashModeSettings SmashSettings;
	UAdultDragonFlightSettings FlightSettings;

	FVector StartPoint;
	FVector ControlPoint;
	FVector EndPoint;
	FVector MovementDirection;

	const float MaxSpinDuration = 1;
	const float MinSpinDuration = 1.0;
	float FindTargetWindow = 0.5;

	float TimeWhenSmahedTarget = 0;
	float SpeedWhenSmashedTarget = 0;

	bool bHasDestroyedTarget = false;
	bool bHasFoundTarget = false;

	float TimeWhenFoundTarget = 0;
	float SpinStopTime = 0;
	float SpinCooldown = 1.0;

	FHazeAcceleratedFloat AccMovementSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlightSettings = UAdultDragonFlightSettings::GetSettings(Player);
		SmashSettings = UAdultDragonTailSmashModeSettings::GetSettings(Player);

		DragonComp = UPlayerTailAdultDragonComponent::Get(Player);
		SmashComp = UAdultDragonHomingTailSmashComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);

		BoundarySpline = TListedActors<AAdultDragonBoundarySpline>().GetSingle();

		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FAdultTailDragonHomingTailSmashActivateParams& Params) const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (DragonComp.bGapFlying)
			return false;

		// ignore cooldown if we have a target
		if (SmashComp.SmashTargetComp == nullptr)
		{
			if (Time::GetGameTimeSince(SpinStopTime) < SpinCooldown)
				return false;
		}

		Params.TargetComp = SmashComp.SmashTargetComp;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!bHasFoundTarget && ActiveDuration > MinSpinDuration)
			return true;

		if (bHasFoundTarget && Time::GetGameTimeSince(TimeWhenFoundTarget) > MaxSpinDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FAdultTailDragonHomingTailSmashActivateParams Params)
	{
		DragonComp.Speed = Math::Max(DragonComp.Speed, SmashSettings.MinSpeed);

		DragonComp.AimingInstigators.Add(this);
		Player.PlayForceFeedback(SmashComp.SmashStartedForceFeedback, false, true, this);
		Player.PlayCameraShake(SmashComp.SmashImpactCameraShake, this, 1.0);

		bHasDestroyedTarget = false;
		bHasFoundTarget = Params.TargetComp != nullptr;
		SmashComp.SmashTargetComp = Params.TargetComp;

		if (bHasFoundTarget)
		{
			FVector ToTarget = (SmashComp.SmashTargetComp.WorldLocation - Player.ActorLocation);
			StartPoint = Player.ActorLocation;
			ControlPoint = BoundarySpline.GetClampedLocationWithinBoundary(Player.ActorLocation + (ToTarget * 0.2) + Player.ActorForwardVector * 3000);
			EndPoint = BoundarySpline.GetClampedLocationWithinBoundary(SmashComp.SmashTargetComp.WorldLocation);
			TimeWhenFoundTarget = Time::GameTimeSeconds;
		}

		MovementDirection = Player.ActorForwardVector;

		Player.ApplyCameraSettings(SmashComp.CameraSettings, 0.5, this, EHazeCameraPriority::MAX);

		AccMovementSpeed.SnapTo(DragonComp.GetMovementSpeed());

		FAdultDragonHomingTailSmashTriggeredParams EventParams;
		EventParams.DragonMesh = DragonComp.DragonMesh;
		UAdultDragonHomingTailSmashEffectHandler::Trigger_TailSmashTriggered(Player, EventParams);

		// Don't judge me I know what I'm doing
		auto Dragon = Cast<AHazeActor>(DragonComp.DragonMesh.Owner);
		UAdultDragonHomingTailSmashEffectHandler::Trigger_TailSmashTriggered(Dragon, EventParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AimingInstigators.RemoveSingleSwap(this);
		DragonComp.BonusSpeed.Remove(this);
		DragonComp.AnimParams.AnimAirSmashRoll.SnapTo(0.0);
		SmashComp.bHasSmashedActor = bHasDestroyedTarget;

		SpeedEffect::ClearSpeedEffect(Player, this);
		Player.ClearCameraSettingsByInstigator(this, 2.5);
		SpinStopTime = Time::GameTimeSeconds;
	}

	UFUNCTION(CrumbFunction)
	void CrumbCalculatePathToTarget(USceneComponent TargetComp)
	{
		SmashComp.SmashTargetComp = TargetComp;
		TimeWhenFoundTarget = Time::GameTimeSeconds;

		FVector ToTarget = (SmashComp.SmashTargetComp.WorldLocation - Player.ActorLocation);
		StartPoint = Player.ActorLocation;

		ControlPoint = BoundarySpline.GetClampedLocationWithinBoundary(Player.ActorLocation + (ToTarget * 0.2) + Player.ActorForwardVector * 3000);
		EndPoint = BoundarySpline.GetClampedLocationWithinBoundary(SmashComp.SmashTargetComp.WorldLocation);

		bHasFoundTarget = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bHasFoundTarget && ActiveDuration < FindTargetWindow)
		{
			if (SmashComp.SmashTargetComp != nullptr)
			{
				CrumbCalculatePathToTarget(SmashComp.SmashTargetComp);
			}
		}

		HandleMovement(DeltaTime);

		TrySmashAtHead();
		DragonComp.RequestLocomotionDragonAndPlayer(AdultDragonTailSmash::Locomotion::AirSmash);
		UpdateSpeedEffects();
	}

	void TrySmashAtHead()
	{
		FHazeTraceSettings TraceSettings;
		TraceSettings.TraceWithChannel(ECollisionChannel::WeaponTraceZoe);
		TraceSettings.IgnorePlayers();
		TraceSettings.UseSphereShape(3000);
		FVector JawLocation = DragonComp.DragonMesh.GetSocketLocation(n"Jaw");
		auto Overlaps = TraceSettings.QueryOverlaps(JawLocation);
		for (auto Overlap : Overlaps)
		{
			if (Overlap.Component == nullptr)
				continue;

			auto ResponseComp = UAdultDragonTailSmashModeResponseComponent::Get(Overlap.Component.Owner);
			if (ResponseComp != nullptr)
			{
				FTailSmashModeHitParams HitParams;
				HitParams.HitComponent = Overlap.Component;
				Overlap.Component.GetClosestPointOnCollision(JawLocation, HitParams.ImpactLocation);
				HitParams.FlyingDirection = Player.ActorForwardVector;
				HitParams.DamageDealt = SmashSettings.ImpactDamage;

				CrumbSendHit(HitParams, ResponseComp);
			}
		}
	}

	void HandleMovement(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			// Before smashing a target we use the additive curve to control speed
			// We use the fractioncurve to slowdown the speed based on what we had at at moment of impact
			if (bHasDestroyedTarget)
			{
				float SlowdownActiveDuration = Time::GetGameTimeSince(TimeWhenSmahedTarget);
				float CurrentSpeedFraction = SmashComp.SlowdownSpinSpeedFractionCurve.GetFloatValue(SlowdownActiveDuration);
				DragonComp.BonusSpeed.Add(this, SpeedWhenSmashedTarget * CurrentSpeedFraction);
			}

			if (bHasFoundTarget && !bHasDestroyedTarget)
			{
				float ActiveMoveDuration = Time::GetGameTimeSince(TimeWhenFoundTarget);
				float AdditiveSpeed = SmashComp.AdditiveSpinSpeedCurve.GetFloatValue(ActiveMoveDuration);
				DragonComp.BonusSpeed.Add(this, AdditiveSpeed);
				float Alpha = Math::Saturate(ActiveMoveDuration / 0.25);
				FVector NewLocation = BezierCurve::GetLocation_1CP(StartPoint, ControlPoint, EndPoint, Alpha);
				MovementDirection = (NewLocation - Player.ActorLocation).GetSafeNormal();
				if (MovementDirection.IsNearlyZero())
					MovementDirection = Player.ActorForwardVector;

				// Debug::DrawDebugSphere(StartPoint, 1500, 12, FLinearColor::Yellow, 25, 0, true);
				// Debug::DrawDebugSphere(ControlPoint, 1500, 12, FLinearColor::LucBlue, 25, 0, true);
				// Debug::DrawDebugSphere(EndPoint, 1500, 12, FLinearColor::DPink, 25, 0, true);
			}

			float MovementSpeed = Math::Max(DragonComp.GetMovementSpeed(), 0);

			AccMovementSpeed.AccelerateTo(MovementSpeed, 0.2, DeltaTime);

			FVector DesiredDelta = MovementDirection * MovementSpeed * DeltaTime;
			FVector NewLocation = BoundarySpline.GetClampedLocationWithinBoundary(Player.ActorLocation + DesiredDelta);
			FVector MovementDelta = NewLocation - Player.ActorLocation;

			Movement.InterpRotationTo(MovementDelta.ToOrientationQuat(), AdultDragonHomingTailSmash::SpinRotationInterpSpeed, false);
			Movement.AddDelta(MovementDelta);
			MoveComp.ApplyMove(Movement);
		}
	}

	void UpdateSpeedEffects()
	{
		// camera postprocessing
		float SpeedFraction = Math::NormalizeToRange(Player.ActorVelocity.Size(), FlightSettings.MinSpeed, FlightSettings.MaxSpeed);
		SpeedEffect::RequestSpeedEffect(Player, FlightSettings.SpeedEffectValue.GetFloatValue(SpeedFraction * 4), this, EInstigatePriority::High);
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	void CrumbSendHit(FTailSmashModeHitParams Params, UAdultDragonTailSmashModeResponseComponent HitComp)
	{
		if (HitComp != nullptr)
			HitComp.ActivateSmashModeHit(Params);

		Player.PlayCameraShake(SmashComp.SmashImpactCameraShake, this, 2.5);
		Player.PlayForceFeedback(SmashComp.SmashImpactForceFeedback, false, true, this);
		SmashComp.SmashTargetComp = nullptr;
		if (!bHasDestroyedTarget)
		{
			TimeWhenSmahedTarget = Time::GameTimeSeconds;
			bHasDestroyedTarget = true;
			DragonComp.BonusSpeed.Find(this, SpeedWhenSmashedTarget);
			MovementDirection = Player.ActorForwardVector;
		}
	}
};