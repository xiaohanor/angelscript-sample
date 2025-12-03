class UIslandWalkerClusterMineFollowCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local; // Lots of mines, move them locally

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;

	AIslandWalkerClusterMine Mine;
	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;
	UIslandWalkerPhaseComponent WalkerPhaseComp;
	UIslandWalkerSettings Settings;

	const bool bSpin = false;
	const float SpinUpTime = 0.2;
	const float SpinUpDuration = 2.0;
	const float SpinTopSpeed = 360.0 * 0.0;
	const float JumpSpeed = 1000.0;
	const float Friction = 3.0;
	const float FollowRange = 1200.0;
	const float ReachedRange = 120.0;
	const float TelegraphDuration = 1.4;
	const FVector Gravity = FVector(0.0, 0.0, -982.0 * 3.0);
	const float FlipSpeed = 1.7;

	FHazeAcceleratedFloat AccYawSpeed;
	bool bChasingTarget = false;
	float MoveTime = 1.5;
	float InitialPauseDuration = 0.5;
	bool bWasJumping = false;
	FVector FlipNormal;
	float FlipAlpha = 1.0;
	FQuat FlipStartQuat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mine = Cast<AIslandWalkerClusterMine>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		Mine.Mesh.RelativeRotation = FRotator::ZeroRotator;
		FlipAlpha = 1.0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Mine.bLanded)
			return false;
		if (Mine.bExploded)
			return false;
		if (MoveComp.HasMovedThisFrame())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Mine.bLanded)
			return true;
		if (Mine.bExploded)
			return true;
		if (MoveComp.HasMovedThisFrame())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WalkerPhaseComp = UIslandWalkerPhaseComponent::Get(Mine.ProjectileComp.Launcher);
		Settings = UIslandWalkerSettings::GetSettings(Mine.ProjectileComp.Launcher);
		InitialPauseDuration = Math::RandRange(0.8, 1.2);
		MoveTime = BIG_NUMBER;
		bChasingTarget = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;		
		float CurTime = Time::GameTimeSeconds;

		// Check if we should retarget
		AHazePlayerCharacter Other = (Mine.Target != nullptr) ? Mine.Target.OtherPlayer : Game::GetClosestPlayer(Owner.ActorLocation);
		if (!IsValidTarget(Mine.Target, FollowRange) && IsValidTarget(Other, FollowRange))
			Mine.Target = Other;

		if (bSpin && (ActiveDuration > SpinUpTime))
		{
			// Spin!
			AccYawSpeed.AccelerateTo(SpinTopSpeed, SpinUpDuration, DeltaTime);
			FRotator NewRot = Owner.ActorRotation;
			NewRot.Yaw += AccYawSpeed.Value * DeltaTime;
			if (NewRot.Yaw > 360.0)
				NewRot.Yaw -= 360.0;
			Movement.SetRotation(NewRot);		
		}

		if (bWasJumping && MoveComp.IsOnAnyGround())
		{
			bWasJumping = false;
			UIslandWalkerClusterMineEventHandler::Trigger_OnMovementLand(Owner);
		}

		if (!bChasingTarget && (ActiveDuration > InitialPauseDuration) && ShouldMoveTowardsTarget(FollowRange))
		{
			// Jump straight up to telegraph chasing
			bChasingTarget = true;
			Movement.AddVelocity(FVector::UpVector * 1500.0);
			MoveTime = ActiveDuration + TelegraphDuration;
			if (!bWasJumping)
			{
				UIslandWalkerClusterMineEventHandler::Trigger_OnMovementJump(Owner);
				bWasJumping = true;
				Flip(Owner.ActorForwardVector);
			}
		}

		if (bChasingTarget)
		{
			if ((ActiveDuration > MoveTime) && MoveComp.IsOnAnyGround())
			{
				// Jump towards target intermittently
				if (!IsValidTarget(Mine.Target, FollowRange + 100.0))
				{
					bChasingTarget = false;
				}
				else if (!Mine.ActorLocation.IsWithinDist(Mine.Target.ActorLocation, ReachedRange))
				{
					FVector TargetDir = (Mine.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();
					Movement.AddVelocity((TargetDir + FVector::UpVector * 1.2)* JumpSpeed);
					if (!bWasJumping)
					{
						UIslandWalkerClusterMineEventHandler::Trigger_OnMovementJump(Owner);
						bWasJumping = true;
						Flip(FVector::UpVector.CrossProduct(TargetDir));
					}
				}
				
				MoveTime = ActiveDuration + Math::RandRange(0.8, 1.3);
			}

			if (Mine.ExplodeTime > CurTime + Settings.ClusterMineTelegraphExplosionTime)
			{
				for (AHazePlayerCharacter Player : Game::Players)
				{
					if (Player.HasControl() && 
						Player.ActorLocation.IsWithinDist(Owner.ActorLocation, Settings.ClusterMineNearPlayerRange) && 
						SceneView::IsInView(Player, Owner.ActorLocation))
						CrumbPrimeExplosion(Settings.ClusterMineTelegraphExplosionTime);
				}
			}
		}

		if (FlipAlpha < 1.0)
		{
			// Continue flipping over
			FlipAlpha = Math::Min(1.0, FlipAlpha + FlipSpeed * DeltaTime);
			Mine.Mesh.WorldRotation = (FQuat(FlipNormal, PI * FlipAlpha) * FlipStartQuat).Rotator(); 
		}
		else
		{
			// Align with ground, normally or upside down
			FQuat MeshQuat = Mine.Mesh.WorldTransform.Rotation;
			FQuat Target = FQuat::MakeFromZX(FVector::UpVector * ((MeshQuat.UpVector.Z > 0.0) ? 1.0 : -1.0), MeshQuat.ForwardVector);
			Mine.Mesh.WorldRotation = FQuat::Slerp(MeshQuat, Target, DeltaTime * 4.0).Rotator();
		}

		// Maintain current velocity with friction applied
		FVector Velocity = MoveComp.Velocity;
		Velocity *= Math::Pow(Math::Exp(-Friction), DeltaTime);
		Movement.AddVelocity(Velocity);

		Movement.AddAcceleration(Gravity);

		MoveComp.ApplyMove(Movement);

		if ((WalkerPhaseComp.Phase != EIslandWalkerPhase::Suspended) && Mine.ProjectileComp.Launcher.HasControl())
		{
			// Mines should auto-explode after a while when walker has moved on to next phase
			if (Mine.ExplodeTime > CurTime + 4.0)	
				CrumbPrimeExplosion(Math::RandRange(0.0, 4.0));
		}
	}

	void Flip(FVector Normal)
	{
		if (FlipAlpha < 1.0)
			return;
		FlipNormal = Normal;
		if (FlipNormal.IsNearlyZero())
			FlipNormal = Owner.ActorRightVector;
		FlipAlpha = 0.0;
		FlipStartQuat = Mine.Mesh.WorldTransform.Rotation;
	}

	UFUNCTION(CrumbFunction)
	void CrumbPrimeExplosion(float ExplosionDelay)
	{
		// Network this to guarantee telegraph effect starts before explosion
		Mine.ExplodeTime = Time::GameTimeSeconds + ExplosionDelay;
	}

	bool IsValidTarget(AHazePlayerCharacter Target, float Range)
	{
		if (Target == nullptr)
			return false;
		if (Target.IsPlayerDead())
			return false;
		if (!Mine.ActorLocation.IsWithinDist(Target.ActorLocation, Range))
			return false;
		return true;
	}

	bool ShouldMoveTowardsTarget(float Range)
	{
		if (!IsValidTarget(Mine.Target, Range))
			return false;
		if (Mine.ActorLocation.IsWithinDist(Mine.Target.ActorLocation, ReachedRange))
			return false;
		return true;
	}
}
