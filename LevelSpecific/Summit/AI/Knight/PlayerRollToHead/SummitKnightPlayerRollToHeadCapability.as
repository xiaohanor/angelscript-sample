class USummitKnightPlayerRollToHeadCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	// default CapabilityTags.Add(CapabilityTags::Movement); // This gets blocked by teen dragon sheet
	default CapabilityTags.Add(n"SummitKnightRollToHead");

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::InfluenceMovement;

	USummitKnightPlayerRollToHeadComponent RollComp;
	UPlayerMovementComponent MoveComp;
	UPlayerTailTeenDragonComponent DragonComp;
	UTeleportingMovementData Movement;
	USummitKnightSettings KnightSettings;
	USummitKnightHelmetComponent KnightHelmet;

	float RollCompleteTime = BIG_NUMBER;
	bool bHasImpacted = false;
	float AccumulatedTime = 0.0;
	UAnimSequence RollAnim;
	float MoveFactor = 1.0;
	float SmashHeadMaxTime = BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RollComp = USummitKnightPlayerRollToHeadComponent::GetOrCreate(Player);
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
		if (RollComp.Type != EKnightPlayerRollToHeadType::RollUpBlades)
			return false;
		if (RollComp.KnightMesh == nullptr)
			return false; // Rail smash behaviour has not yet detected player starting to roll up blades
		if (!RollComp.KnightMesh.Owner.IsA(AAISummitKnight))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (ActiveDuration > RollCompleteTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		KnightSettings = USummitKnightSettings::GetSettings(Cast<AHazeActor>(RollComp.KnightMesh.Owner));
		KnightHelmet = USummitKnightHelmetComponent::Get(RollComp.KnightMesh.Owner);

		USummitKnightAnimationComponent KnightAnimComp = USummitKnightAnimationComponent::Get(RollComp.KnightMesh.Owner);
		RollAnim = KnightAnimComp.PlayerRollToHeadAnimation;
		FHazePlaySlotAnimationParams Params;
		Params.Animation = RollAnim;
		Params.BlendTime = 0.1;
		Params.BlendOutTime = 0.3;
		Params.bExtractRootMotion = false; // We apply root motion ourselves
		UPlayerTeenDragonComponent::Get(Owner).DragonMesh.PlaySlotAnimation(Params);
		RollCompleteTime = RollAnim.PlayLength;
		bHasImpacted = false;
		AccumulatedTime = 0.0;

		// Get approximate location of where knights head will be when we hit it. 
		FVector HeadTargetLoc = RollComp.KnightMesh.Owner.ActorTransform.TransformPosition(FVector(2800.0, 0.0, 1700.0));

		// Slide into place. Note that this also does a movement transition sync so we can continue with local movement.
		// TODO: Start with offset in animation when closer to head so we always blend in a forward direction
		FVector Location = Player.ActorLocation;
		FRotator Rotation = FRotator::ZeroRotator;
		Rotation.Yaw = (HeadTargetLoc - Location).Rotation().Yaw;
		Player.SmoothTeleportActor(Location, Rotation, this, 0.6);

		FTransform HandTransform = RollComp.KnightMesh.GetSocketTransform(n"RightAttach");
		FVector IdealLocation = HandTransform.TransformPosition(FVector(-100.0, 120.0, -1800.0));
		MoveFactor = Location.Dist2D(HeadTargetLoc) / IdealLocation.Dist2D(HeadTargetLoc);

		SmashHeadMaxTime = BIG_NUMBER;
		if (RollComp.bWillSmash)
			SmashHeadMaxTime = Location.Distance(HeadTargetLoc) / 4000.0;

		// In case we clip with knight, we set a hefty min range for camera
		UCameraSettings::GetSettings(Player).MinDistance.Apply(400.0, this, 0.0, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AAISummitKnight Knight = Cast<AAISummitKnight>(RollComp.KnightMesh.Owner);
		RollComp.KnightMesh = nullptr;
		RollComp.Type = EKnightPlayerRollToHeadType::None;
		UCameraSettings::GetSettings(Player).MinDistance.Clear(this, 0.0);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		if (!bHasImpacted && RollComp.bWillSmash && HasControl())
			CrumbSmashHead(Knight);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bHasImpacted && RollComp.bWillSmash && HasControl())
		{
			FVector HeadLoc = RollComp.KnightMesh.GetSocketLocation(n"Head");
			if (Player.ActorLocation.IsWithinDist(HeadLoc, KnightSettings.FinalRailSmashHitHeadRange) || 
				(ActiveDuration > SmashHeadMaxTime)) // Safety backup in case something steers us away from head
			{
				bHasImpacted = true;		
				if (!KnightHelmet.bCollision)
					CrumbSmashHead(Cast<AAISummitKnight>(RollComp.KnightMesh.Owner));
			}
		}  

		if (DeltaTime == 0.0)
			return;
		if (Owner.AttachParentActor != nullptr)
			return; // We've become attached to something (from levelscript?) at end of roll
		if (!MoveComp.PrepareMove(Movement))
			return;

		// Locally simulated movement so we sync with knight
		FHazeLocomotionTransform RootMotion;
		if (RollAnim.ExtractRootMotion(AccumulatedTime, ActiveDuration, RootMotion))
		{
			FVector Delta = DragonComp.DragonMesh.Owner.ActorTransform.TransformVector(RootMotion.DeltaTranslation);
			Delta.X *= MoveFactor;
			Delta.Y *= MoveFactor;
			FVector Velocity = Delta / DeltaTime;
			Movement.AddDeltaWithCustomVelocity(Delta, Velocity);
		}

		DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::RollMovement);
		MoveComp.ApplyMove(Movement);

		AccumulatedTime = ActiveDuration;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSmashHead(AAISummitKnight Knight)
	{
		Knight.OnHeadSmashedByDragon.Broadcast();
	}
};