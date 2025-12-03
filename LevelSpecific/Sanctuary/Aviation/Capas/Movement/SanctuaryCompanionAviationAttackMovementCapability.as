class USanctuaryCompanionAviationAttackMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default DebugCategory = AviationCapabilityTags::Aviation;
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 50;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryCompanionAviationDestinationComponent Phase1DestinationComp;
	USanctuaryCompanionAviationPlayerComponent AviationComp;
	USanctuaryCompanionMegaCompanionPlayerComponent CompanionComp;
	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	float CurrentSpeed;
	FVector EntryDirection;
	FVector SafeDirection;
	
	FHazeAcceleratedRotator TargetRotation;
	FHazeAcceleratedVector TargetLocation;

	float SpawnVFXCooldown = 0.0;

	bool bSnappedTransform;
	bool bMovingToStart = false;
	float MovingToStartEndTimestamp = 0.0;
	bool bWasAttackCircling = false;
	bool bExitCapability = false;
	FHazeAcceleratedTransform AccTransform;
	FTransform AttackCirclingTransform;
	FVector AttackUpVector;

	FHazeRuntimeSpline CirclingSpline;

	TArray<FVector> SplinePoints;
	int Granularity = 8;
	default SplinePoints.Reserve(Granularity);

	bool bDebug = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
		Phase1DestinationComp = USanctuaryCompanionAviationDestinationComponent::GetOrCreate(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!AviationComp.GetIsAviationActive())
			return false;

		if (!AviationComp.HasDestination())
			return false;

		if (!IsInStateHandledByThisCapability())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!AviationComp.GetIsAviationActive())
			return true;

		if (!AviationComp.HasDestination())
			return true;

		if (bExitCapability)
			return true;

		if (!IsInStateHandledByThisCapability())
			return true;

		return false;
	}

	bool IsInStateHandledByThisCapability() const
	{
		// if (AviationComp.AviationState == EAviationState::InitAttack)
		// 	return true;

		if (AviationComp.AviationState == EAviationState::Attacking)
			return true;

		if (AviationComp.AviationState == EAviationState::TryExitAttack)
			return true;

		if (AviationComp.AviationState == EAviationState::AttackingSuccessCircling)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BlockedWhileIn::AirMotion, this);

		if (CompanionComp == nullptr)
			CompanionComp = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Owner);
		CompanionComp.SyncedDiscLocation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		CompanionComp.SyncedDiscUpvector.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		CompanionComp.SyncedDiscRadius.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);

		if (!HasControl())
			return;

		TargetRotation.SnapTo(Owner.ActorRotation);
		CurrentSpeed = MoveComp.Velocity.Size();
		EntryDirection = Owner.ActorForwardVector;
		SafeDirection = EntryDirection;
		AviationComp.SyncedKillValue.SetValue(1.0);
		TargetLocation.SnapTo(Owner.ActorLocation);
		TargetLocation.Velocity = MoveComp.Velocity;

		bSnappedTransform = false;
		bWasAttackCircling = false;
		bMovingToStart = true;
		bExitCapability = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BlockedWhileIn::AirMotion, this);
		if (AviationComp.GetIsAviationActive())
			AviationComp.SetAviationState(EAviationState::Exit);

		CompanionComp.SyncedDiscLocation.OverrideSyncRate(EHazeCrumbSyncRate::Low);
		CompanionComp.SyncedDiscUpvector.OverrideSyncRate(EHazeCrumbSyncRate::Low);
		CompanionComp.SyncedDiscRadius.OverrideSyncRate(EHazeCrumbSyncRate::Low);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				BuildSpline(DeltaTime);
				if (bDebug)
					CirclingSpline.DrawDebugSpline(150, 5.0, 0.0, true);

				// Find location ahead
				float SplineDist = CirclingSpline.GetClosestSplineDistanceToLocation(Player.ActorLocation);
				FVector NewTargetPos = GetTargetLocation(SplineDist);
				if (bDebug)
					Debug::DrawDebugSphere(NewTargetPos, 100.0, 12, ColorDebug::Magenta, 30.0, 0.0, true);

				// We have different rotation speed when "Starting". 
				// This is why we have the distinction of bMovingToStart
				if (bMovingToStart)
				{
					float DistanceToSpline = (CirclingSpline.GetLocationAtDistance(CirclingSpline.GetClosestSplineDistanceToLocation(Player.ActorLocation)) - Owner.ActorLocation).Size();
					FVector DirectionToTarget = (NewTargetPos - Owner.ActorLocation).GetSafeNormal();
					MovingToStartEndTimestamp = ActiveDuration;
					if (DistanceToSpline < 1000.0 && DirectionToTarget.DotProduct(Owner.ActorForwardVector) > 0.5) // location & orientation close enough
						bMovingToStart = false;
				}
				
				TargetLocation.AccelerateTo(NewTargetPos, 0.1, DeltaTime); // Maybe we should accelerate towards target dir instead of target location
				FVector ToTargetDirection = (TargetLocation.Value - Owner.ActorLocation).GetSafeNormal();

				float DynamicMoveSpeed = Math::EaseInOut(AviationComp.Settings.StrangleTightenSpeed, AviationComp.Settings.StrangleSlowSpeed, AviationComp.SyncedKillValue.Value, 2.0);
				float StartAlpha = Math::Clamp(ActiveDuration / 3.0, 0.0, 1.0);
				float MoveSpeed = Math::Lerp(AviationComp.Settings.StrangleStartSpeed, DynamicMoveSpeed, StartAlpha);
				Movement.AddVelocity(ToTargetDirection * MoveSpeed);

				// Quit attack if appropriate and aligned OK. We want to exit in ish same direction as we entered
				if (AviationComp.AviationState == EAviationState::TryExitAttack && EntryDirection.DotProduct(ToTargetDirection) > 0.6)
					bExitCapability = true; 

				UpdateRotation(ToTargetDirection, SplineDist, DeltaTime);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			SpawnVFXCooldown -= DeltaTime;
			if (AviationComp.AviationState != EAviationState::AttackingSuccessCircling && AviationComp.SyncedKillValue.Value < KINDA_SMALL_NUMBER && SpawnVFXCooldown < 0.0)
			{
				SpawnVFXCooldown = 0.1;
				if (AviationComp.AttackingEffect != nullptr)
					Niagara::SpawnOneShotNiagaraSystemAttached(AviationComp.AttackingEffect, Owner.RootComponent);
			}
		}
	}

	private FVector GetTargetLocation(float SplineDist)
	{
		float CircleFraction = CirclingSpline.Length * 0.1;
		float TargetDistance = SplineDist + CircleFraction;
		if (TargetDistance > CirclingSpline.Length)
			TargetDistance -= CirclingSpline.Length;
		if (TargetDistance < 0.0)
			TargetDistance += CirclingSpline.Length;
		return CirclingSpline.GetLocationAtDistance(TargetDistance);
	}

	private void UpdateRotation(FVector ToTargetDirection, float SplineDist, float DeltaTime)
	{
		// Interpolate our accelerating Rotation Duration. We want the circling rotation to conform quickly but the start to be more slow / smooooooth
		// So we need to interpolate the desired durations to not get a hard snap
		const float SecondsToInterpolate = 2.0;
		float SoftLerp = Math::Clamp((ActiveDuration - MovingToStartEndTimestamp) / SecondsToInterpolate, 0.0, 1.0);
		float RotationAccDuration = Math::Lerp(0.7, 0.1, SoftLerp);
		
		FVector TargetForward = ToTargetDirection;
		FVector TargetUp = FVector::UpVector;
		FLinearColor DebugColorring = ColorDebug::Yellow;
		if (!bMovingToStart)
		{
			DebugColorring = ColorDebug::Magenta;
			TargetForward = CirclingSpline.GetTangent(SplineDist / CirclingSpline.Length).GetSafeNormal();
			if (AviationComp.Settings.bStrangleCircleUseBoneZ)
			{
				FVector RightVector = (AccTransform.Value.Location - Owner.ActorLocation).GetSafeNormal() * Phase1DestinationComp.GetSignClockwiseAttack();
				TargetUp = TargetForward.CrossProduct(RightVector).GetSafeNormal();
			}
		}
			
		if (bDebug)
		{
			Debug::DrawDebugString(Owner.ActorLocation, "" + SoftLerp, ColorDebug::Cerulean, 0.0, 1.0);
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + TargetForward * 1000.0, DebugColorring, 15.0, 0.0, true);
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + TargetUp * 1000.0, ColorDebug::Cerulean, 15.0, 0.0, true);
		}

		TargetRotation.AccelerateTo(FRotator::MakeFromXZ(TargetForward, TargetUp), RotationAccDuration, DeltaTime);
		Movement.SetRotation(TargetRotation.Value);
	}

	private void BuildSpline(float DeltaTime)
	{
		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		FTransform AttackTranform = bWasAttackCircling ? AttackCirclingTransform : DestinationData.SkellyMesh.GetSocketTransform(DestinationData.BoneName);
		if (!bWasAttackCircling && AviationComp.AviationState == EAviationState::AttackingSuccessCircling)
		{
			AttackCirclingTransform = AttackTranform;
			bWasAttackCircling = true;
		}
		if (!bSnappedTransform)
		{
			bSnappedTransform = true;
			AccTransform.SnapTo(AttackTranform);
		}
		AccTransform.AccelerateTo(AttackTranform, 1.0, DeltaTime); // We accelerate the transform to minimize jittery hula hooping around hydra neck, from the struggling animation

		float Radius = Math::EaseInOut(AviationComp.Settings.StranglingMinRadius, AviationComp.Settings.StranglingMaxRadius, AviationComp.SyncedKillValue.Value, 2.0);
		AttackUpVector = AttackTranform.Rotation.UpVector;
		CirclingSpline.Looping = true;
		SplinePoints.Reset(Granularity);
		float DegreesPerStep = 360.0 / Granularity;
		FVector CircleUpVector = AviationComp.Settings.bStrangleCircleUseBoneZ ? AccTransform.Value.Rotation.UpVector : FVector::UpVector;
		for (int i = 0; i < Granularity; ++i)
		{
			FVector OutwardsDir = Math::RotatorFromAxisAndAngle(CircleUpVector, DegreesPerStep * i * Phase1DestinationComp.GetSignClockwiseAttack()).ForwardVector;
			SplinePoints.Add(AccTransform.Value.Location + OutwardsDir * Radius);
		}

		CompanionComp.SyncedDiscLocation.SetValue(AccTransform.Value.Location);
		CompanionComp.SyncedDiscUpvector.SetValue(CircleUpVector);
		CompanionComp.SyncedDiscRadius.SetValue(Radius);

		CirclingSpline.SetPoints(SplinePoints);
		CirclingSpline.SetCustomEnterTangentPoint(CirclingSpline.GetTangent(1.0));
	}
}