delegate void FOnRaderAttackComplete();

class UMeltdownBossPhaseThreeSpinnerAttackComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AMeltdownBossPhaseThreeLavaMoleProjectile> ProjectileClass;
	UPROPERTY()
	TSubclassOf<AMeltdownBossPhaseThreeLavaMole> LavaMolePortalClass;

	AMeltdownBossPhaseThreeExecutionerSpinner Spinner;

	AMeltdownBossPhaseThreeLavaMole LeftMolePortal;
	AMeltdownBossPhaseThreeLavaMole RightMolePortal;

	bool bStartedShooting = false;
	bool bShotLeftThisFrame = false;
	bool bShotRightThisFrame = false;
	bool bIsAttackDone = false;
}

namespace MeltdownPhaseThree
{

struct FMeltdownPhaseThreeSpinnerStartParams
{
	AMeltdownBossPhaseThreeExecutionerSpinner Spinner;
}

UFUNCTION()
void StartSpinnerPortalAttack(AMeltdownPhaseThreeBoss Rader, AMeltdownBossPhaseThreeExecutionerSpinner Spinner)
{
	if (!Rader.HasControl())
		return;

	FMeltdownPhaseThreeSpinnerStartParams StartParams;
	StartParams.Spinner = Spinner;

	Rader.ActionQueue.Capability(UMeltdownBossPhaseThreeSpinnerAttackIntro, StartParams);
	Rader.ActionQueue.Idle(2.2);
	Rader.ActionQueue.Capability(UMeltdownBossPhaseThreeSpinnerAttackLaunch);
	Rader.ActionQueue.Idle(1.0);
	Rader.ActionQueue.Capability(UMeltdownBossPhaseThreeSpinnerAttackShoot);
	Rader.ActionQueue.Capability(UMeltdownBossPhaseThreeSpinnerAttackFinish);
}

class UMeltdownBossPhaseThreeSpinnerAttackIntro : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AMeltdownPhaseThreeBoss Rader;
	UMeltdownBossPhaseThreeSpinnerAttackComponent AttackComp;
	FMeltdownPhaseThreeSpinnerStartParams Params;

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FMeltdownPhaseThreeSpinnerStartParams QueueParams)
	{
		Params = QueueParams;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownPhaseThreeBoss>(Owner);
		AttackComp = UMeltdownBossPhaseThreeSpinnerAttackComponent::GetOrCreate(Rader);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > 6.3)
			return true;
		if (Rader.IsDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AttackComp.Spinner = Params.Spinner;
		AttackComp.bStartedShooting = false;
		AttackComp.bIsAttackDone = false;

		Rader.CurrentLocomotionTag = n"SpinnerPortal";
		Rader.PortalLocomotionTag = n"SpinnerPortal";

		AttackComp.Spinner.RootComponent.SetAbsolute(false, false, true);
		AttackComp.Spinner.AttachToComponent(Rader.Mesh, n"RightAttach");
		AttackComp.Spinner.Appear();
		AttackComp.Spinner.Head.SetHiddenInGame(true);
		AttackComp.Spinner.Body.UnHideBoneByName(n"Head");
		AttackComp.Spinner.AddActorVisualsBlock(this);
		AttackComp.Spinner.Rader = Rader;

		AttackComp.Spinner.Body.AttachToComponent(Rader.Mesh);

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = AttackComp.Spinner.BodyAnimation;
		AttackComp.Spinner.Body.PlaySlotAnimation(AnimParams);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > 0.3)
			AttackComp.Spinner.RemoveActorVisualsBlock(this);

		if(Rader.GlobalParameters != nullptr)
		{
			if (ActiveDuration > 2.0 && ActiveDuration < 3.0)
			{
				Rader.SetPortalState(Rader.PortalMesh, Rader.PortalTextureExecutioner);
				Rader.SetPortalClipSphereEnabled(Rader.PortalMesh, true);
			}
			if (ActiveDuration > 4.0)
			{
				Rader.SetPortalClipSphereEnabled(Rader.PortalMesh, false);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AttackComp.Spinner.RemoveActorVisualsBlock(this);
		AttackComp.Spinner.Head.SetHiddenInGame(false);
		AttackComp.Spinner.Body.HideBoneByName(n"Head", EPhysBodyOp::PBO_None);
		Rader.PortalLocomotionTag = NAME_None;

		Rader.SetPortalClipSphereEnabled(Rader.PortalMesh, false);
	}
}

class UMeltdownBossPhaseThreeSpinnerAttackLaunch : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AMeltdownPhaseThreeBoss Rader;
	UMeltdownBossPhaseThreeSpinnerAttackComponent AttackComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownPhaseThreeBoss>(Owner);
		AttackComp = UMeltdownBossPhaseThreeSpinnerAttackComponent::Get(Rader);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > 1.8)
			return true;
		if (Rader.IsDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AttackComp.bStartedShooting = true;
		AttackComp.Spinner.DetachRootComponentFromParent();
		AttackComp.Spinner.StartSpinning();
		AttackComp.Spinner.ActorLocation = Rader.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Open the shooting portals
		AttackComp.LeftMolePortal = SpawnActor(AttackComp.LavaMolePortalClass);
		if (AttackComp.LeftMolePortal != nullptr)
		{
			AttackComp.LeftMolePortal.AttachToComponent(Rader.Mesh, n"LeftHandMiddle1");
			AttackComp.LeftMolePortal.SetActorRelativeLocation(FVector(7.75, 0, 0));
			AttackComp.LeftMolePortal.SetActorRelativeRotation(FRotator(0,90,0));
			if (!Rader.IsDead())
				AttackComp.LeftMolePortal.OpenPortal();
			else
				AttackComp.LeftMolePortal.AddActorVisualsBlock(n"RaderDead");
		}

		AttackComp.RightMolePortal = SpawnActor(AttackComp.LavaMolePortalClass);
		if (AttackComp.RightMolePortal != nullptr)
		{
			AttackComp.RightMolePortal.AttachToComponent(Rader.Mesh, n"RightHandMiddle1");
			AttackComp.RightMolePortal.SetActorRelativeLocation(FVector(7.75, 0, 0));
			AttackComp.RightMolePortal.SetActorRelativeRotation(FRotator(0,-90,0));
			if (!Rader.IsDead())
				AttackComp.RightMolePortal.OpenPortal();
			else
				AttackComp.RightMolePortal.AddActorVisualsBlock(n"RaderDead");
		}
	}
}

struct FMeltdownBossPhaseThreeSpinnerProjectileActivationParams
{
	FVector TargetLocation;
}

class UMeltdownBossPhaseThreeSpinnerAttackShoot : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AMeltdownPhaseThreeBoss Rader;
	UMeltdownBossPhaseThreeSpinnerAttackComponent AttackComp;

	int ProjectileIndex = 0;
	AHazePlayerCharacter TargetPlayer;
	float Timer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownPhaseThreeBoss>(Owner);
		AttackComp = UMeltdownBossPhaseThreeSpinnerAttackComponent::Get(Rader);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsValid(AttackComp.Spinner))
			return true;
		if (AttackComp.Spinner.IsActorDisabled())
			return true;
		if (Rader.IsDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Timer -= DeltaTime;
		if (Timer <= 0.0 && !Rader.IsDead())
		{
			if (HasControl())
			{
				AHazePlayerCharacter PlayerTarget;
				if (ProjectileIndex % 5 == 0)
					PlayerTarget = Game::Mio;
				else
					PlayerTarget = Game::Zoe;

				FVector TargetLocation = PlayerTarget.ActorLocation;
				TargetLocation += PlayerTarget.ActorHorizontalVelocity.GetSafeNormal2D() * 250.0;
				TargetLocation.Z = AttackComp.Spinner.ActorLocation.Z;

				CrumbShoot(TargetLocation);
			}

			Timer += 0.5;
		}
		else
		{
			AttackComp.bShotLeftThisFrame = false;
			AttackComp.bShotRightThisFrame = false;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbShoot(FVector TargetLocation)
	{
		FTransform SpawnTransform;
		AMeltdownBossPhaseThreeLavaMole LavaMole;
		if (ProjectileIndex % 2 == 0)
		{
			SpawnTransform = AttackComp.LeftMolePortal.ShootLocation.WorldTransform;
			LavaMole = AttackComp.LeftMolePortal;
			AttackComp.bShotLeftThisFrame = true;
		}
		else
		{
			SpawnTransform = AttackComp.RightMolePortal.ShootLocation.WorldTransform;
			LavaMole = AttackComp.RightMolePortal;
			AttackComp.bShotRightThisFrame = true;
		}

		AMeltdownBossPhaseThreeLavaMoleProjectile Projectile = SpawnActor(AttackComp.ProjectileClass, SpawnTransform.Location, SpawnTransform.Rotator(), bDeferredSpawn = true);
		Projectile.SpawnerLavaMole = LavaMole;
		FinishSpawningActor(Projectile);

		UMeltdownBossPhaseThreeLavaMoleEffectHandler::Trigger_Spawn(LavaMole);

		FVector Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(
			SpawnTransform.Location,
			TargetLocation,
			Projectile.Gravity,
			Projectile.HorizontalSpeed,
		);

		Projectile.Launch(TargetLocation, Velocity);
		ProjectileIndex += 1;
	}
}

class UMeltdownBossPhaseThreeSpinnerAttackFinish : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AMeltdownPhaseThreeBoss Rader;
	UMeltdownBossPhaseThreeSpinnerAttackComponent AttackComp;

	bool bStoppedSpinning = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownPhaseThreeBoss>(Owner);
		AttackComp = UMeltdownBossPhaseThreeSpinnerAttackComponent::Get(Rader);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > 5.0)
			return true;
		if (Rader.IsDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AttackComp.bIsAttackDone = true;
		bStoppedSpinning = false;

		Timer::SetTimer(this, n"RemoveShips", 1.5);

		if (Rader.IsDead())
		{
			AttackComp.LeftMolePortal.AddActorDisable(this);
			AttackComp.RightMolePortal.AddActorDisable(this);
		}
	}

	UFUNCTION()
	private void RemoveShips()
	{
		AttackComp.LeftMolePortal.DetachRootComponentFromParent();
		AttackComp.LeftMolePortal.ClosePortal();
		
		AttackComp.RightMolePortal.DetachRootComponentFromParent();
		AttackComp.RightMolePortal.ClosePortal();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Rader.OnExecutionerAttackFinished.Broadcast();
		if (!bStoppedSpinning)
			AttackComp.Spinner.StopSpinning();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bStoppedSpinning && ActiveDuration > 2.3)
		{
			bStoppedSpinning = true;
			AttackComp.Spinner.StopSpinning();
		}
	}
}

}