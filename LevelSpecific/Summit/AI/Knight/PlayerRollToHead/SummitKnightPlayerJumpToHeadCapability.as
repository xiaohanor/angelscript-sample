class USummitKnightPlayerJumpToHeadCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	// default CapabilityTags.Add(CapabilityTags::Movement); // This gets blocked by teen dragon sheet
	default CapabilityTags.Add(n"SummitKnightJumpToHead");

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::InfluenceMovement;

	USummitKnightPlayerRollToHeadComponent RollToHeadComp;
	UPlayerMovementComponent MoveComp;
	UPlayerTailTeenDragonComponent DragonComp;
	UTeleportingMovementData Movement;
	USummitKnightSettings KnightSettings;
	USummitKnightHelmetComponent KnightHelmet;
	UTeenDragonRollComponent DragonRollComp;

	FVector CurveStart;
	float CurveAlpha;
	float CurveAlphaPerSecond;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RollToHeadComp = USummitKnightPlayerRollToHeadComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (UPlayerTailTeenDragonComponent::Get(Player) == nullptr)
			return false;
		if (RollToHeadComp.Type != EKnightPlayerRollToHeadType::JumpToHead)
			return false;
		if (RollToHeadComp.KnightMesh == nullptr)
			return false; // Rail smash behaviour has not yet detected player starting to roll up blades
		if (!RollToHeadComp.KnightMesh.Owner.IsA(AAISummitKnight))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (CurveAlpha > 1.0 - SMALL_NUMBER)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		DragonRollComp = UTeenDragonRollComponent::Get(Player);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		KnightSettings = USummitKnightSettings::GetSettings(Cast<AHazeActor>(RollToHeadComp.KnightMesh.Owner));
		KnightHelmet = USummitKnightHelmetComponent::Get(RollToHeadComp.KnightMesh.Owner);

		CurveAlpha = 0.0;
		CurveStart = Player.ActorLocation;
		FVector CurveEnd = RollToHeadComp.KnightMesh.GetSocketLocation(n"Head");
		CurveAlphaPerSecond = KnightSettings.FinalSmashPlayerJumpToHeadSpeed / Math::Max(1.0, CurveStart.Dist2D(CurveEnd));

		FVector JumpVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(CurveStart, CurveEnd, 982.0 * 3.0, KnightSettings.FinalSmashPlayerJumpToHeadSpeed);
		Player.SetActorVelocity(JumpVelocity);

		// In case we clip with knight, we set a hefty min range for camera
		UCameraSettings::GetSettings(Player).MinDistance.Apply(400.0, this, 0.0, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AAISummitKnight Knight = Cast<AAISummitKnight>(RollToHeadComp.KnightMesh.Owner);
		RollToHeadComp.Type = EKnightPlayerRollToHeadType::None;
		RollToHeadComp.KnightMesh = nullptr;
		UCameraSettings::GetSettings(Player).MinDistance.Clear(this, 0.0);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		if ((CurveAlpha > 0.75) && !KnightHelmet.bCollision && HasControl())
			CrumbDamageHead(Knight);
		RollToHeadComp.bWillSmash = false;

		FTeenDragonRollWallKnockbackParams KnockbackParams;
		KnockbackParams.AdditionalImpulse.Set((Knight.ActorForwardVector + FVector::UpVector * 0.5).GetSafeNormal() * 2000.0);
		DragonRollComp.KnockbackParams.Set(KnockbackParams);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (DeltaTime == 0.0)
			return;
		if (!MoveComp.PrepareMove(Movement))
			return;

		float DeltaAlpha = CurveAlphaPerSecond * DeltaTime;
		CurveAlpha += DeltaAlpha;	
		CurveStart = Player.ActorLocation;		
		FVector CurveEnd = RollToHeadComp.KnightMesh.GetSocketLocation(n"Head");
		FVector CurveControl = CurveStart + MoveComp.Velocity.GetClampedToMaxSize(CurveStart.Distance(CurveEnd) * 0.75);
		FVector NewLoc = BezierCurve::GetLocation_1CP(CurveStart, CurveControl, CurveEnd, DeltaAlpha);
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, (NewLoc - Player.ActorLocation) / DeltaTime);
		MoveComp.ApplyMove(Movement);
		DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::RollMovement);

#if EDITOR
		if (RollToHeadComp.KnightMesh.Owner.bHazeEditorOnlyDebugBool)
			BezierCurve::DebugDraw_1CP(CurveStart, CurveControl, CurveEnd, FLinearColor::Yellow, 5.0);
#endif		
	}

	UFUNCTION(CrumbFunction)
	void CrumbDamageHead(AAISummitKnight Knight)
	{
		Knight.OnHeadDamagedByDragon.Broadcast();
	}
};