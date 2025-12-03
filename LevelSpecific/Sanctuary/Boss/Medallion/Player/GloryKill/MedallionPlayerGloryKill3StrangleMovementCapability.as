class UMedallionPlayerGloryKill3StrangleMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionGloryKill);
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 60;

	UMedallionPlayerGloryKillComponent GloryKillComp;
	UMedallionPlayerReferencesComponent RefsComp;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData MoveData;

	FHazeAcceleratedQuat AccPlayerDirection;

	FVector StrangleCenterDirection;
	FStickSnapbackDetector SnapbackDetector;

	float TetherLength = 0.0;

	FVector LastInput;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::GetOrCreate(Owner);
		MoveData = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (RefsComp.Refs.GloryKillCirclingSpotTemp == nullptr)
			return false;
		if (GloryKillComp.GloryKillState != EMedallionGloryKillState::Strangle)
			return false;
		if (Player.bIsControlledByCutscene)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GloryKillComp.GloryKillState == EMedallionGloryKillState::Strangle)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FVector OuterPoint = RefsComp.Refs.GloryKillCirclingSpotTemp.GetClosestPointOnDonut(Player.MeshOffsetComponent.WorldLocation);
		FVector FromTetherToPlayer =  Player.ActorLocation - OuterPoint;
		TetherLength = FromTetherToPlayer.Size();

		StrangleCenterDirection = FromTetherToPlayer.GetSafeNormal();
		AccPlayerDirection.SnapTo(FQuat::MakeFromXZ(StrangleCenterDirection, FVector::UpVector));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.bIsControlledByCutscene) // can happen on remote in network
			return;

		FVector DesiredDelta;
		FRotator DesiredRotation;
		if (HasControl())
		{
			FVector OuterPoint = RefsComp.Refs.GloryKillCirclingSpotTemp.GetClosestPointOnDonut(Player.MeshOffsetComponent.WorldLocation);
			FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			//bool bControlResetFeedback = RawStick.Size() < 0.1;

			const FVector StickInput(RawStick.X, RawStick.Y, 0);
			FVector NoSnapInput = SnapbackDetector.RemoveStickSnapbackJitter(StickInput, StickInput);

			if (NoSnapInput.Size() > KINDA_SMALL_NUMBER)
				LastInput = NoSnapInput;
			else
				NoSnapInput = LastInput;
	
			FVector DesiredDirection = StrangleCenterDirection;
			FVector InputDirection;

			// if (Math::Abs(NoSnapInput.X) > KINDA_SMALL_NUMBER || Math::Abs(NoSnapInput.Y) > KINDA_SMALL_NUMBER)
			// {
			// 	// not working correctly atm, needs more work
			// 	FRotator HeadingDirection = FRotator::MakeFromZX(FVector::UpVector, StrangleCenterDirection);
			// 	if (SanctuaryMedallionHydraDevToggles::Draw::HydraStrangling.IsEnabled())
			// 		Debug::DrawDebugCoordinateSystem(OuterPoint, HeadingDirection, 5000, 10);
			// 	InputDirection = HeadingDirection.UpVector * NoSnapInput.X;
			// 	InputDirection += HeadingDirection.ForwardVector * NoSnapInput.Y;
			// 	InputDirection = DesiredDirection.GetSafeNormal();
			// 	if (InputDirection.DotProduct(StrangleCenterDirection) > 0.0)
			// 		DesiredDirection = InputDirection;
			// }

			const float MaxAngleDegrees = 30.0;  
			if (SanctuaryMedallionHydraDevToggles::Draw::HydraStrangling.IsEnabled())
			{
				PrintToScreen("" + NoSnapInput);
				Debug::DrawDebugCone(OuterPoint, StrangleCenterDirection, TetherLength, MaxAngleDegrees, MaxAngleDegrees, true, 12, ColorDebug::Gray, 8, 0.0, true);
				if (InputDirection.Size() > KINDA_SMALL_NUMBER)
					Debug::DrawDebugLine(OuterPoint, OuterPoint + InputDirection * TetherLength, Player.GetPlayerUIColor(), 35, 0.0, true);
				Debug::DrawDebugLine(OuterPoint, OuterPoint + DesiredDirection * TetherLength, ColorDebug::White, 10, 0.0, true);
			}

			// 
			FVector ClampedDirection = DesiredDirection.ClampInsideCone(StrangleCenterDirection, MaxAngleDegrees);
			AccPlayerDirection.ThrustTo(FQuat::MakeFromXZ(ClampedDirection, FVector::UpVector), 30.0, DeltaTime);
			// 

			float Length = TetherLength * Math::EaseOut(1.0, 1.35, GloryKillComp.AccStrangle.Value, 2);
			FVector FromStranglePoint = AccPlayerDirection.Value.ForwardVector;
			FVector TargetLocation = OuterPoint + FromStranglePoint.GetSafeNormal() * Length;

			FVector Delta = TargetLocation - Player.ActorLocation;
			DesiredDelta = Delta;
			DesiredRotation = FRotator::MakeFromXZ(FromStranglePoint.GetSafeNormal(), FVector::UpVector);
		}

		if (!MoveComp.PrepareMove(MoveData, DesiredRotation.UpVector))
			return;

		if (HasControl())
		{
			MoveData.AddDelta(DesiredDelta);
			MoveData.SetRotation(DesiredRotation);
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}
		MoveComp.ApplyMove(MoveData);
	}
};