class UTundraPlayerTreeGuardianRangedShootCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 75;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"TundraPlayerTreeGuardianRangedShootCapability");

	UTreeGuardianRangedShootIgnoreOcclusionCollisionContainerComponent CollisionContainerComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;
	UTundraTreeGuardianRangedShootTargetable Target;
	UTundraPlayerTreeGuardianSettings Settings;

	UTundraTreeGuardianRangedInteractionTargetableComponent InteractionTargetable;

	bool bPullingInProjectile = false;
	bool bLaunched = false;
	FTransform OriginalProjectileTransform;
	FQuat OriginalPlayerRotation;
	FQuat TargetPlayerRotation;

	const float TargetMoveToTreeGuardianDuration = 0.5;
	const float AdditionalDelayBeforeShoot = 0.4;
	const float ShootAnimationDuration = 1.6;
	const float FullAnimationDuration = TargetMoveToTreeGuardianDuration + AdditionalDelayBeforeShoot + ShootAnimationDuration;
	const float PlayerRotationDurationToProjectile = 0.2;
	const float PlayerRotationDurationToTarget = AdditionalDelayBeforeShoot;
	const float ObstacleCheckSphereRadius = 1200.0;
	const float ObstacleLerpDuration = 1.0;
	
	float TimeOfAttach = 0.0;
	float TimeOfStartRotating = 0.0;
	float CurrentRotationDuration;
	bool bIsAttached = false;
	bool bEffectsApplied = false;
	bool bMoveHorizontally = false;
	FVector OriginalHorizontalLocation;
	FVector TargetHorizontalLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CollisionContainerComp = UTreeGuardianRangedShootIgnoreOcclusionCollisionContainerComponent::GetOrCreate(Game::Mio);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
		Settings = UTundraPlayerTreeGuardianSettings::GetSettings(Player);
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerTreeGuardianRangedShootActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(ShapeshiftingComp.GetCurrentShapeType() != ETundraShapeshiftShape::Big)
			return false;

		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable == nullptr)
			return false;

		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable.IsDisabledForPlayer(Player))
			return false;

		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable.InteractionType != ETundraTreeGuardianRangedInteractionType::Shoot)
			return false;

		if(!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		auto Targetable = Cast<UTundraTreeGuardianRangedShootTargetable>(PlayerTargetablesComp.GetPrimaryTarget(UTundraTreeGuardianRangedShootTargetable));

		Params.Targetable = TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable;
		Params.ShootTargetable = Targetable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration > FullAnimationDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerTreeGuardianRangedShootActivatedParams Params)
	{
		Player.BlockCapabilities(CapabilityTags::Death, this);
		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingActivation, this);
		Player.BlockCapabilities(n"Knockdown", this);
		Player.BlockCapabilities(n"Stumble", this);
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big);
		bPullingInProjectile = true;
		bMoveHorizontally = false;
		bLaunched = false;

		InteractionTargetable = Params.Targetable;
		InteractionTargetable.Owner.AddActorCollisionBlock(this);

		Player.BlockCapabilitiesExcluding(TundraRangedInteractionTags::RangedInteractionAiming, TundraRangedInteractionTags::RangedInteractionAimingCameraExclusion,  this);

		Target = Params.ShootTargetable;
		TreeGuardianComp.CurrentRangedShootTargetable = Target;
		InteractionTargetable.CommitInteract();
		OriginalProjectileTransform = InteractionTargetable.Owner.ActorTransform;

		StartRotatingToFaceTarget(OriginalProjectileTransform.Location, PlayerRotationDurationToProjectile);

		FTundraPlayerTreeGuardianRangedShootParams EffectParams;
		EffectParams.Projectile = Cast<AHazeActor>(InteractionTargetable.Owner);
		UTreeGuardianBaseEffectEventHandler::Trigger_OnRangedShootStartPullingProjectile(TreeGuardianComp.TreeGuardianActor, EffectParams);

		ApplyFeedback();
		CheckShouldMoveHorizontally();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Death, this);
		Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingActivation, this);
		Player.UnblockCapabilities(TundraRangedInteractionTags::RangedInteractionAiming, this);
		Player.UnblockCapabilities(n"Knockdown", this);
		Player.UnblockCapabilities(n"Stumble", this);

		if(InteractionTargetable.Owner != nullptr)
			InteractionTargetable.Owner.RemoveActorCollisionBlock(this);

		TreeGuardianComp.CurrentRangedShootTargetable = nullptr;

		if(InteractionTargetable != nullptr)
		{
			InteractionTargetable.StopInteract();
			if(bIsAttached)
				Detach();

			bIsAttached = false;
		}

		if(bEffectsApplied)
			ClearFeedback();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if(bMoveHorizontally)
				{
					float Alpha = ActiveDuration / ObstacleLerpDuration;
					Alpha = Math::Saturate(Alpha);
					Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);
					FVector NewLocation = Math::Lerp(OriginalHorizontalLocation, TargetHorizontalLocation, Alpha);

					Movement.AddDelta(NewLocation - Player.ActorLocation, EMovementDeltaType::HorizontalExclusive);
				}

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				HandleRotation();
			}
			else
			{
				if(MoveComp.HasGroundContact())
					Movement.ApplyCrumbSyncedGroundMovement();
				else
					Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"ShootProjectile");
		}

		if(bPullingInProjectile)
		{
			float Alpha = ActiveDuration / TargetMoveToTreeGuardianDuration;
			Alpha = Math::Saturate(Alpha);
			Alpha = Math::ExpoIn(0.0, 1.0, Alpha);

			if(Math::IsNearlyEqual(Alpha, 1.0))
			{
				Alpha = 1.0;
				bPullingInProjectile = false;
				Attach();

				if(HasControl())
					CrumbStartRotating();
			}
			else
			{
				UHazeSkeletalMeshComponentBase TreeGuardianMesh = TreeGuardianComp.GetShapeMesh();
				FTransform SocketTransform = TreeGuardianMesh.GetSocketTransform(n"RightAttach");

				FVector NewLocation = Math::Lerp(OriginalProjectileTransform.Location, SocketTransform.Location, Alpha);
				FQuat NewRotation = FQuat::Slerp(OriginalProjectileTransform.Rotation, SocketTransform.Rotation, Alpha);
				if(InteractionTargetable.HasControl())
				{
					InteractionTargetable.Owner.ActorLocation = NewLocation;
					InteractionTargetable.Owner.ActorQuat = NewRotation;
				}
			}
		}

		if(bIsAttached)
		{
			FVector Location = Player.ActorCenterLocation;
			FRotator SphereBaseRotation = FRotator::MakeFromXZ((InteractionTargetable.Owner.ActorLocation - Location).VectorPlaneProject(FVector::UpVector), FVector::UpVector);
			InteractionTargetable.Owner.ActorQuat = Math::RotatorFromAxisAndAngle(SphereBaseRotation.RightVector, (ActiveDuration * 500.0) % 360.0).Quaternion() * SphereBaseRotation.Quaternion();
		}

		if(!bLaunched && bIsAttached && Time::GetGameTimeSince(TimeOfAttach) > AdditionalDelayBeforeShoot)
		{
			if(HasControl())
			{
				CrumbLaunch(Target);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStartRotating()
	{
		if(Target != nullptr)
			StartRotatingToFaceTarget(Target.WorldLocation, PlayerRotationDurationToTarget);
	}

	void StartRotatingToFaceTarget(FVector TargetLocation, float Duration)
	{
		OriginalPlayerRotation = Player.ActorQuat;
		FVector Direction = (TargetLocation - Player.ActorLocation).GetSafeNormal2D();
		TargetPlayerRotation = FQuat::MakeFromXZ(Direction, FVector::UpVector);
		TimeOfStartRotating = Time::GetGameTimeSeconds();
		CurrentRotationDuration = Duration;
	}

	void ApplyFeedback()
	{
		Player.ApplyCameraSettings(TreeGuardianComp.RangedShootCameraSettings, TreeGuardianComp.RangedShootCameraBlendInTime, this, EHazeCameraPriority::VeryHigh);
		Player.PlayCameraShake(TreeGuardianComp.RangedShootCameraShake, this);

		auto CameraSettings = UCameraSettings::GetSettings(Player);
		FHazeCameraClampSettings ClampSettings;
		ClampSettings.ApplyClampsYaw(Settings.MaxAngleToShootTargetableFromPlayerForward, Settings.MaxAngleToShootTargetableFromPlayerForward);
		CameraSettings.Clamps.Apply(ClampSettings, n"RangedShootClamps", 0.5, EHazeCameraPriority::VeryHigh, 10);

		bEffectsApplied = true;
	}

	void ClearFeedback()
	{
		Player.ClearCameraSettingsByInstigator(this, TreeGuardianComp.RangedShootCameraBlendOutTime);
		Player.StopCameraShakeByInstigator(this, false);

		UCameraSettings::GetSettings(Player).Clamps.Clear(n"RangedShootClamps");

		bEffectsApplied = false;
	}

	void Attach()
	{
		UHazeSkeletalMeshComponentBase TreeGuardianMesh = TreeGuardianComp.GetShapeMesh();
		InteractionTargetable.Owner.RootComponent.AttachToComponent(TreeGuardianMesh, n"RightAttach");
		InteractionTargetable.Owner.RootComponent.bAbsoluteRotation = true;
		TimeOfAttach = Time::GetGameTimeSeconds();
		bIsAttached = true;
	}

	void Detach()
	{
		InteractionTargetable.Owner.RootComponent.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		InteractionTargetable.Owner.RootComponent.bAbsoluteRotation = false;
		bIsAttached = false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunch(UTundraTreeGuardianRangedShootTargetable Targetable)
	{
		bLaunched = true;
		InteractionTargetable.StartInteract();
		Detach();
		
		InteractionTargetable.OnShootInteractLaunch.Broadcast(Targetable, Player.ActorForwardVector.RotateAngleAxis(-10.0, Player.ActorRightVector).RotateAngleAxis(20.0, FVector::UpVector));

		FTundraPlayerTreeGuardianRangedShootParams EffectParams;
		EffectParams.Projectile = Cast<AHazeActor>(InteractionTargetable.Owner);
		UTreeGuardianBaseEffectEventHandler::Trigger_OnRangedShootShootProjectile(TreeGuardianComp.TreeGuardianActor, EffectParams);
	}

	void HandleRotation()
	{
		float Alpha = Time::GetGameTimeSince(TimeOfStartRotating) / CurrentRotationDuration;
		Alpha = Math::Saturate(Alpha);
		Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);

		FQuat NewRotation = FQuat::Slerp(OriginalPlayerRotation, TargetPlayerRotation, Alpha);
		Movement.SetRotation(NewRotation);
	}

	void CheckShouldMoveHorizontally()
	{
		const FString Category = "CheckShouldMoveHorizontally()";

		// OLIVERL TODO: Do overlap check and get closest point on collision to know what points you should depenetrate out from.
		// Determine if we need to move horizontally and to what location.
		const FVector Center = Player.ActorCenterLocation;
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Camera);
		Trace.UseSphereShape(ObstacleCheckSphereRadius);
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(Center);

#if !RELEASE
		TEMPORAL_LOG(this)
			.OverlapResults(f"{Category};Overlaps", Overlaps, Trace.ShapeWorldOffset)
		;
#endif

		TArray<FVector> PointsInside;
		for(FOverlapResult Overlap : Overlaps.BlockHits)
		{
			if(CollisionContainerComp.IgnoreOcclusionActors.Contains(Overlap.Actor))
				continue;

			if(CollisionContainerComp.IgnoreOcclusionComponents.Contains(Overlap.Component))
				continue;

			FVector Point;
			if(Overlap.Component.GetClosestPointOnCollision(Center, Point) <= 0.0f)
				continue;

			if(Point.Z < Player.ActorLocation.Z + Player.ScaledCapsuleHalfHeight * 0.5)
				continue;

			if(Point.DistSquared(Center) < Math::Square(ObstacleCheckSphereRadius))
				PointsInside.Add(Point);

#if !RELEASE
			TEMPORAL_LOG(this)
				.Point(f"{Category};Point {PointsInside.Num() - 1} ({Overlap.Actor.ActorNameOrLabel})", Point, 15.f)
			;
#endif
		}

		if(PointsInside.Num() == 0)
			return;

		float FurthestSqrDist = 0.0;
		for(FVector Point : PointsInside)
		{
			FVector ProjectedPoint = Point.PointPlaneProject(Player.ActorLocation, Player.ActorUpVector);
			FLineSphereIntersection Intersection = Math::GetLineSegmentSphereIntersectionPoints(
				Player.ActorLocation, 
				Player.ActorLocation + TargetPlayerRotation.ForwardVector * (ObstacleCheckSphereRadius * 2.0),
				ProjectedPoint, 
				ObstacleCheckSphereRadius
			);

			if(!Intersection.bHasIntersection)
				continue;

			float SqrDist = Player.ActorLocation.DistSquared(Intersection.MaxIntersection);
			if(SqrDist > FurthestSqrDist)
				FurthestSqrDist = SqrDist;
		}

		if(FurthestSqrDist == 0.0)
			return;

		bMoveHorizontally = true;
		FVector Origin = Player.ActorLocation;
		FVector Destination = Origin + TargetPlayerRotation.ForwardVector * Math::Sqrt(FurthestSqrDist);
		Destination.Z = Origin.Z;

		OriginalHorizontalLocation = Origin;
		TargetHorizontalLocation = Destination;

#if !RELEASE
		TEMPORAL_LOG(this)
			.Point("Target Horizontal Location", TargetHorizontalLocation)
		;
#endif
	}
}

struct FTundraPlayerTreeGuardianRangedShootActivatedParams
{
	UTundraTreeGuardianRangedInteractionTargetableComponent Targetable;
	UTundraTreeGuardianRangedShootTargetable ShootTargetable;
}