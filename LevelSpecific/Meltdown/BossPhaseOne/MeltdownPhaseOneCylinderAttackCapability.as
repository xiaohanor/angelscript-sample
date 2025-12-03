struct FMeltdownPhaseOneCylinderAttackDangerZone
{
	UMeltdownBossCubeGridDisplacementComponent DisplacementComp;
	float Timer = 0.0;
}

class UMeltdownPhaseOneCylinderAttackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	AMeltdownBossPhaseOne Rader;

	TArray<FMeltdownPhaseOneCylinderAttackDangerZone> DangerZones;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownBossPhaseOne>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Rader.CurrentAttack == EMeltdownPhaseOneAttack::Cylinder && Rader.ActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Rader.CurrentAttack != EMeltdownPhaseOneAttack::Cylinder && Rader.CurrentAttack != EMeltdownPhaseOneAttack::None)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (int i = 0; i < 10; ++i)
		{
			for (int y = 0; y < 10; ++y)
			{
				AMeltdownBossCubeGrid CubeGrid = Rader.ArenaBlocks[i].Blocks[y];
				// CubeGrid.bDisableDisplacement = true;
				CubeGrid.AttachToComponent(Rader.SpinnerAttack.Root, NAME_None, EAttachmentRule::KeepWorld);
			}
		}

		AddDangerZone(Rader.ArenaBlocks[3].Blocks[0], 0.0);
		AddDangerZone(Rader.ArenaBlocks[3].Blocks[4], 0.1);
		AddDangerZone(Rader.ArenaBlocks[0].Blocks[0], 0.2);
		AddDangerZone(Rader.ArenaBlocks[2].Blocks[2], 0.3);
		AddDangerZone(Rader.ArenaBlocks[1].Blocks[5], 0.5);
		AddDangerZone(Rader.ArenaBlocks[0].Blocks[4], 0.6);
		AddDangerZone(Rader.ArenaBlocks[0].Blocks[8], 0.7);
		AddDangerZone(Rader.ArenaBlocks[2].Blocks[7], 0.8);
		AddDangerZone(Rader.ArenaBlocks[3].Blocks[9], 0.9);
		AddDangerZone(Rader.ArenaBlocks[5].Blocks[7], 0.0);
		AddDangerZone(Rader.ArenaBlocks[5].Blocks[9], 0.1);
		AddDangerZone(Rader.ArenaBlocks[5].Blocks[0], 0.2);
		AddDangerZone(Rader.ArenaBlocks[6].Blocks[5], 0.3);
		AddDangerZone(Rader.ArenaBlocks[5].Blocks[3], 0.4);
		AddDangerZone(Rader.ArenaBlocks[6].Blocks[1], 0.5);
		AddDangerZone(Rader.ArenaBlocks[7].Blocks[6], 0.6);
		AddDangerZone(Rader.ArenaBlocks[7].Blocks[8], 0.7);
		AddDangerZone(Rader.ArenaBlocks[9].Blocks[7], 0.0);
		AddDangerZone(Rader.ArenaBlocks[9].Blocks[2], 0.1);
		AddDangerZone(Rader.ArenaBlocks[7].Blocks[3], 0.2);
		AddDangerZone(Rader.ArenaBlocks[8].Blocks[9], 0.4);
		AddDangerZone(Rader.ArenaBlocks[8].Blocks[0], 0.5);
		AddDangerZone(Rader.ArenaBlocks[9].Blocks[5], 0.9);
		AddDangerZone(Rader.ArenaBlocks[9].Blocks[4], 0.0);

		UMeltdownPhaseOneCylinderAttackEffectHandler::Trigger_StartCylinderAttack(Rader);

		Rader.ActionQueue.Idle(3.17);
		Rader.ActionQueue.Duration(0.67, this, n"BendArena");
		Rader.ActionQueue.Event(this, n"StartSpinner");
		Rader.ActionQueue.Idle(12.0);
		Rader.ActionQueue.Event(this, n"StopSpinner");
		Rader.ActionQueue.Duration(0.67, this, n"UnbendArena");
		Rader.ActionQueue.Event(this, n"FinishSpinner");
		Rader.ActionQueue.Idle(1.66);

		for (auto Player : Game::Players)
			UMovementStandardSettings::SetWalkableSlopeAngle(Player, 75.0, this);
	}

	void AddDangerZone(AMeltdownBossCubeGrid Grid, float Delay)
	{
		UMeltdownBossCubeGridDisplacementComponent DisplacementComp = UMeltdownBossCubeGridDisplacementComponent::Create(Grid);
		DisplacementComp.AttachToComponent(Grid.InstancedMesh);
		DisplacementComp.SetRelativeLocation(FVector(200, 200, 0));
		DisplacementComp.Type = EMeltdownBossCubeGridDisplacementType::Shape;
		DisplacementComp.Shape = FHazeShapeSettings::MakeSphere(150);
		DisplacementComp.LerpDistance = 100.0;
		DisplacementComp.Displacement = FVector(0, 0, 0);
		DisplacementComp.bDisplacementInRelativeSpace = true;
		DisplacementComp.Redness = 1.0;
		DisplacementComp.WobblePeriod = 1.0;
		DisplacementComp.WobbleDisplacement = FVector(0, 0, 0);
		DisplacementComp.bInfiniteHeight = true;
		DisplacementComp.AffectOnlyGrid = Grid;

		FMeltdownPhaseOneCylinderAttackDangerZone DangerZone;
		DangerZone.Timer = -Delay;
		DangerZone.DisplacementComp = DisplacementComp;
		DangerZones.Add(DangerZone);
	}

	void UpdateDangerZones(float DeltaTime)
	{
		for (FMeltdownPhaseOneCylinderAttackDangerZone& Zone : DangerZones)
		{
			Zone.Timer += DeltaTime;

			if (Zone.Timer < 0.0)
				continue;

			Zone.DisplacementComp.ActivateDisplacement();

			bool bShouldDealDamage = false;
			if (Zone.Timer < 2.0)
			{
				float WobbleAlpha = Math::Saturate(Zone.Timer / 1.0);
				Zone.DisplacementComp.Displacement = FVector(0, 0, 20) * WobbleAlpha;
				Zone.DisplacementComp.WobbleDisplacement = FVector(0, 0, 20) * WobbleAlpha;
				Zone.DisplacementComp.Redness = Math::Lerp(0.0, -0.5, WobbleAlpha);
			}
			else
			{
				float Alpha = Math::Saturate((Zone.Timer - 2.0) / 0.5);
				float RedAlpha = 1.0;
				if (Rader.PlatformMoveIndex == 4)
				{
					Alpha = 1.0 - Rader.PlatformMoveAlpha;
					RedAlpha = Alpha;
					bShouldDealDamage = (Alpha > 0.25);
				}
				else if (Rader.PlatformMoveIndex > 4)
				{
					Alpha = 0;
					RedAlpha = 0;
					bShouldDealDamage = false;
				}
				else
				{
					bShouldDealDamage = true;
				}

				Zone.DisplacementComp.Displacement = FVector(0, 0, 200) * Alpha;
				Zone.DisplacementComp.WobbleDisplacement = FVector(0, 0, 50) * Alpha;
				Zone.DisplacementComp.Redness = RedAlpha;
			}

			if (bShouldDealDamage)
			{
				FVector DamageLocation = Zone.DisplacementComp.WorldTransform.TransformPosition(FVector(0, 0, 400));
				// Debug::DrawDebugSphere(DamageLocation, 230);

				for (auto Player : Game::Players)
				{
					if (Player.CapsuleComponent.IntersectsSphere(DamageLocation, 230))
					{
						Player.DamagePlayerHealth(0.5);

						FVector KnockDirection = (Player.ActorLocation - DamageLocation).GetSafeNormal2D();
						Player.AddKnockbackImpulse(KnockDirection, 1200.0, 1200.0);
					}
				}
			}
		}
	}

	UFUNCTION()
	private void FinishSpinner()
	{
		Rader.PlatformMoveAlpha = 0.0;
		Rader.PlatformMoveIndex = 5;

		for (int i = 0; i < 10; ++i)
		{
			for (int y = 0; y < 10; ++y)
			{
				AMeltdownBossCubeGrid CubeGrid = Rader.ArenaBlocks[i].Blocks[y];
				CubeGrid.bDisableDisplacement = false;
				CubeGrid.InstancedMesh.SetRelativeTransform(FTransform());
				CubeGrid.DetachRootComponentFromParent(true);
			}
		}
	}

	UFUNCTION()
	private void UnbendArena(float Alpha)
	{
		Rader.PlatformMoveAlpha = Alpha;
		Rader.PlatformMoveIndex = 4;

		for (int i = 0; i < 10; ++i)
		{
			UAnimSequence BendAnim = Rader.UnbendAnimations[i];

			FTransform BoneTransform;
			BendAnim.GetAnimBoneTransform(BoneTransform, n"Base", BendAnim.SequenceLength * Alpha);

			for (int y = 0; y < 10; ++y)
			{
				AMeltdownBossCubeGrid CubeGrid = Rader.ArenaBlocks[i].Blocks[y];
				CubeGrid.InstancedMesh.SetRelativeTransform(BoneTransform);
	//			CubeGrid.InstancedMesh.SetScalarParameterValueOnMaterials(n"Bend1", 0);
			}
		}
	}

	UFUNCTION()
	private void BendArena(float Alpha)
	{
		Rader.PlatformMoveAlpha = Alpha;
		Rader.PlatformMoveIndex = 0;

		for (int i = 0; i < 10; ++i)
		{
			UAnimSequence BendAnim = Rader.BendAnimations[i];

			FTransform BoneTransform;
			BendAnim.GetAnimBoneTransform(BoneTransform, n"Base", BendAnim.SequenceLength * Alpha);

			for (int y = 0; y < 10; ++y)
			{
				AMeltdownBossCubeGrid CubeGrid = Rader.ArenaBlocks[i].Blocks[y];
				CubeGrid.InstancedMesh.SetRelativeTransform(BoneTransform);
		//		CubeGrid.InstancedMesh.SetScalarParameterValueOnMaterials(n"Bend1", Alpha*2);
			}
		}
	}

	UFUNCTION()
	private void StartSpinner()
	{
		UMeltdownPhaseOneCylinderAttackEffectHandler::Trigger_StartRotatingCylinder(Rader);

		Rader.SpinnerAttack.StartSpinner();
	}

	UFUNCTION()
	private void StopSpinner()
	{
		UMeltdownPhaseOneCylinderAttackEffectHandler::Trigger_FinishRotatingCylinder(Rader);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto Zone : DangerZones)
			Zone.DisplacementComp.DestroyComponent(Zone.DisplacementComp);

		for (auto Player : Game::Players)
			UMovementStandardSettings::ClearWalkableSlopeAngle(Player, this);

		UMeltdownPhaseOneCylinderAttackEffectHandler::Trigger_FinishCylinderAttack(Rader);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateDangerZones(DeltaTime);
		if (Rader.Mesh.CanRequestLocomotion())
			Rader.Mesh.RequestLocomotion(n"Cylinder", this);
	}
};

UCLASS(Abstract)
class UMeltdownPhaseOneCylinderAttackEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartCylinderAttack() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartRotatingCylinder() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishRotatingCylinder() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishCylinderAttack() {}
}