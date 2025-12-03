class UMeltdownPhaseThreeOgreAttackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 110; 

	AMeltdownPhaseThreeBoss Rader;
	int ShakeCount = 0;
	bool bHasFinished = false;

	AMeltdownBossPhaseThreeOgreShaker Shaker;

	const int SpawnPerShake = 6;
	const float SpawnInterval = 1.0 / 6.0;

	bool bSpawnOgres = false;
	bool bAnimationStarted;
	float SpawnTimer = 0.0;
	int ShakeSpawnCount = 0;

	int TotalSpawnedOgreCount = 0;

	FHazeAcceleratedRotator RaderRotation;
	FRotator RaderTargetRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownPhaseThreeBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Rader.IsDead())
			return false;
		if (Rader.CurrentAttack == EMeltdownPhaseThreeAttack::OgreShaker)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bHasFinished)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Shaker = TListedActors<AMeltdownBossPhaseThreeOgreShaker>().GetSingle();

		Shaker.RemoveActorDisable(Shaker);
		Shaker.Root.SetAbsolute(false, false, true);
		Shaker.AttachToComponent(Rader.Mesh, n"RightAttach", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);

		ShakeCount = 0;
		bHasFinished = false;
		bSpawnOgres = false;
		bAnimationStarted = false;
		
		RaderTargetRotation = Rader.ActorRotation;
		RaderRotation.SnapTo(RaderTargetRotation);

		UMeltdownPhaseThreeOgrePortalEffectHandler::Trigger_StartOgreShaker(Rader);

		Rader.OgreState = EMeltdownPhasThreeOgreShakeState::Move;
		Rader.bHasLoopedAttackPattern = true;

		Rader.ActionQueue.NetworkSyncPoint(this);
		Rader.ActionQueue.Event(this, n"StartAnimation");
		Rader.ActionQueue.Idle(1.0);
		Rader.ActionQueue.Event(this, n"OpenPortal");
	}

	UFUNCTION()
	private void StartAnimation()
	{
		bAnimationStarted = true;

		Rader.PortalLocomotionTag = n"OgrePortal";
		Rader.PortalMesh.SetSkeletalMeshAsset(Rader.SpherePortalMesh);
		Rader.PortalMesh.AddComponentVisualsBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Rader.PortalMesh.SetSkeletalMeshAsset(Rader.DiscPortalMesh);
		Rader.PortalMesh.RemoveComponentVisualsBlocker(this);
		if (Rader.PortalLocomotionTag == n"OgrePortal")
			Rader.PortalLocomotionTag = NAME_None;

		Rader.StopAttacking();
		Shaker.ShakeComplete.Broadcast();
		UMeltdownPhaseThreeOgrePortalEffectHandler::Trigger_FinishOgreShaker(Rader);
	}

	UFUNCTION()
	private void OpenPortal()
	{
		Rader.PortalMesh.RemoveComponentVisualsBlocker(this);
	}

	UFUNCTION()
	private void HidePortal()
	{
		if (Rader.PortalLocomotionTag == n"OgrePortal")
			Rader.PortalLocomotionTag = NAME_None;
	}

	UFUNCTION()
	private void StartShaking()
	{
		Rader.OgreState = EMeltdownPhasThreeOgreShakeState::Shake;
	}

	UFUNCTION()
	private void StartSpawningOgres()
	{
		bSpawnOgres = true;
		ShakeSpawnCount = 0;
		SpawnTimer = 0;
	}

	UFUNCTION()
	private void FinishShaking()
	{
	}

	UFUNCTION()
	private void FinishAttack()
	{
		bHasFinished = true;
		UMeltdownPhaseThreeOgrePortalEffectHandler::Trigger_FinishOgreShaker(Rader);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Rader.Mesh.CanRequestLocomotion() && bAnimationStarted)
			Rader.Mesh.RequestLocomotion(n"OgrePortal", this);

		if (Rader.IsDead())
		{
			Rader.ActionQueue.Empty();
			Shaker.HidePortal();
			bHasFinished = true;
			return;
		}

		if (Rader.CurrentAttack == EMeltdownPhaseThreeAttack::OgreShaker)
		{
			if (Rader.ActionQueue.IsEmpty())
			{
				if (ShakeCount >= 3)
				{
					Rader.OgreState = EMeltdownPhasThreeOgreShakeState::Done;
					Rader.ActionQueue.Idle(1.5);
					Rader.ActionQueue.Event(this, n"HidePortal");
					Rader.ActionQueue.Idle(1.0);
					Rader.ActionQueue.Event(this, n"FinishAttack");
				}
				else
				{
					Rader.OgreState = EMeltdownPhasThreeOgreShakeState::Move;
					if (ShakeCount != 0)
						MoveRaderAround();

					if (ShakeCount != 0)
						Rader.ActionQueue.Idle(1.33);
					else
						Rader.ActionQueue.Idle(1.5);

					Rader.ActionQueue.Event(this, n"StartShaking");
					Rader.ActionQueue.Idle(1.0);
					Rader.ActionQueue.Event(this, n"StartSpawningOgres");
					Rader.ActionQueue.Idle(1.0);
					Rader.ActionQueue.Event(this, n"FinishShaking");

					ShakeCount += 1;
				}
			}
		}

		if (bSpawnOgres)
		{
			SpawnTimer += DeltaTime;
			if (SpawnTimer > SpawnInterval)
			{
				if (ShakeSpawnCount < SpawnPerShake)
				{
					SpawnOgre();

					SpawnTimer -= SpawnInterval;
					ShakeSpawnCount += 1;
				}
				else
				{
					bSpawnOgres = false;
				}
			}
		}

		RaderRotation.AccelerateToWithStop(RaderTargetRotation, 1.0, DeltaTime, 1.0);
		Rader.SetActorRotation(RaderRotation.Value);
	}

	void MoveRaderAround()
	{
		RaderTargetRotation.Yaw += Math::RandRange(-10.0, 10.0);
		CrumbSetRaderTargetRotation(RaderTargetRotation);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetRaderTargetRotation(FRotator Rotator)
	{
		RaderTargetRotation = Rotator;
	}

	void SpawnOgre()
	{
		if (!HasControl())
			return;

		FVector SpawnLocation = Shaker.ActorCenterLocation;
		float Distance = Math::Lerp(0.0, 800.0, float(ShakeSpawnCount) / float(SpawnPerShake));
		float Angle = Math::Lerp(0.0, 360.0, float(ShakeSpawnCount) / float(SpawnPerShake));

		FVector2D SpawnDir = Math::AngleDegreesToDirection(Angle);
		SpawnLocation.X += SpawnDir.Y * Distance;
		SpawnLocation.Y += SpawnDir.Y * Distance;

		AHazePlayerCharacter TargetPlayer;
		if (TotalSpawnedOgreCount % 2 == ShakeCount % 2)
			TargetPlayer = Game::Mio;
		else
			TargetPlayer = Game::Zoe;

		CrumbSpawnOgre(SpawnLocation, TargetPlayer);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSpawnOgre(FVector SpawnLocation, AHazePlayerCharacter TargetPlayer)
	{
		FRotator SpawnRotation = FRotator::MakeFromZX(FVector::UpVector, Rader.ActorLocation - SpawnLocation);
		SpawnRotation.Yaw += Math::RandRange(-20.0, 20.0);

		AMeltdownBossPhaseThreeOgreAttackIntro Ogre = SpawnActor(Shaker.OgreSpawnIntro, SpawnLocation, SpawnRotation, bDeferredSpawn = true);
		Ogre.ArenaLocation = Rader.ActorLocation;
		Ogre.TargetPlayer = TargetPlayer;
		Ogre.Rader = Rader;
		Ogre.MakeNetworked(this, TotalSpawnedOgreCount);
		FinishSpawningActor(Ogre);

		Ogre.StartFalling();

		TotalSpawnedOgreCount += 1;
	}
};

UCLASS(Abstract)
class UMeltdownPhaseThreeOgrePortalEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartOgreShaker() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishOgreShaker() {}
}