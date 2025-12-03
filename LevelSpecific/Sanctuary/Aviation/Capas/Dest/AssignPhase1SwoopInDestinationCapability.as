struct FSanctuaryCompanionAviationAssignPhase1SwoopInDestinationActivationParams
{
	bool bClockwise = false;
	FVector PlayerLocation;
}

class USanctuaryCompanionAviationAssignPhase1SwoopInDestinationCapability : UHazePlayerCapability
{
	FSanctuaryCompanionAviationAssignPhase1SwoopInDestinationActivationParams ActivationParams;

	default CapabilityTags.Add(AviationCapabilityTags::AviationSequence);
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	USanctuaryCompanionAviationDestinationComponent DestinationComp;
	USanctuaryCompanionMegaCompanionPlayerComponent MegaCompanionComp;
	FVector CachedCenter;

	bool bQueuedInitAttack = false;
	bool bBlockedCompanionAviation = false;

	FHazeRuntimeSpline CirclingSpline;
	float DistanceStartOffset = 1500.0;

	ASanctuaryCompanionAviationSwoopSequence PlayingSequence = nullptr;
	ASanctuaryBossArenaHydraHead MyLeftHydra = nullptr;
	ASanctuaryBossArenaHydraHead MyRightHydra = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = USanctuaryCompanionAviationDestinationComponent::GetOrCreate(Owner);
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
		MegaCompanionComp = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryCompanionAviationAssignPhase1SwoopInDestinationActivationParams& Params) const
	{
		if (DestinationComp.bDevTriggerSwoopInInitAttack)
		{
			Params.bClockwise = ShouldAttackClockwise();
			Params.PlayerLocation = Owner.ActorLocation;
			return true;
		}

		if (Player.IsPlayerDead())
			return false;

		if (AviationComp.AviationState != EAviationState::SwoopInAttack)
			return false;

		Params.bClockwise = ShouldAttackClockwise();
		Params.PlayerLocation = Owner.ActorLocation;
		return true;
	}

	bool ShouldAttackClockwise() const
	{
		TListedActors<ASanctuaryBossArenaHydraHead> HydraHeads;
		FTransform MyHydraTransform;
		FTransform OtherHydraTransform;

		for (ASanctuaryBossArenaHydraHead HydraHead : HydraHeads)
		{
			if (Player.IsSelectedBy(HydraHead.Player))
				MyHydraTransform = HydraHead.ActorTransform;
			if (Player.OtherPlayer.IsSelectedBy(HydraHead.Player))
				OtherHydraTransform = HydraHead.ActorTransform;
		}

		FVector Diff = OtherHydraTransform.Location - MyHydraTransform.Location;
		bool bOtherHydraIsToTheRight = MyHydraTransform.Rotation.RightVector.DotProduct(Diff) > 0.0;

		return bOtherHydraIsToTheRight;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!bQueuedInitAttack)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryCompanionAviationAssignPhase1SwoopInDestinationActivationParams Params)
	{
		ActivationParams = Params;
		bQueuedInitAttack = false;
		if (DestinationComp.bDevTriggerSwoopInInitAttack)
		{
			AviationComp.StartAviation();
		}

		DestinationComp.bAttackClockwise = Params.bClockwise;
		DestinationComp.bShouldTriggerSwoopInAttack = false;

		TListedActors<ASanctuaryBossArenaManager> ArenaOrigoActor;
		check(ArenaOrigoActor.Num() == 1, "More or less than one ASanctuaryBossArenaManager found!");
		ASanctuaryBossArenaManager ArenaManager = ArenaOrigoActor[0];
		CachedCenter = ArenaManager.ActorLocation;

		BuildSwoopInSpline();
		AddPostSwoopInDestinations();
		// StartSwoopInSequence(); // no sequence atm
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DestinationComp.bDevTriggerSwoopInInitAttack = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
#if EDITOR
		if (AviationDevToggles::DrawPath.IsEnabled())
		{
			Debug::DrawDebugString(Player.ActorLocation, "Swoop IN!", ColorDebug::Ruby);
			if (PlayingSequence != nullptr)
			{
				Debug::DrawDebugCoordinateSystem(PlayingSequence.ActorLocation, PlayingSequence.ActorRotation, 500.0, 4.0, 0.0, true);
			}
		}
#endif
	}

	void BuildSwoopInSpline()
	{
		FVector HeightOffset;
		if (DestinationComp.bAttackClockwise)
			HeightOffset += FVector::UpVector * AviationComp.Settings.InitiateAttackHeightClockwise;
		else
			HeightOffset += FVector::UpVector * AviationComp.Settings.InitiateAttackHeightCounterClockwise;

		TArray<FVector> SplinePoints;
		int NumPoints = 8;
		float AngleStep = PI * 2.0 / Math::FloorToFloat(NumPoints);

		FQuat StartRotation = (Player.ActorLocation - CachedCenter).ToOrientationQuat();
		// FQuat DiffBetweenTargetAndPart = ToTarget.ToOrientationQuat() * PartWorldRot.Inverse();
		// TargetQuat = DiffBetweenTargetAndPart * BallBoss.ActorQuat;
		for (int iPoint = 0; iPoint < NumPoints; ++iPoint)
		{
			FQuat AddedRotation = FQuat(FVector::UpVector, AngleStep * iPoint * DestinationComp.GetSignClockwiseAttack());
			FQuat FinalRotation = AddedRotation * StartRotation;
			FVector SplinePoint = FinalRotation.ForwardVector * AviationComp.Settings.InitiateAttackRadius;
			SplinePoint += HeightOffset;
			SplinePoint += CachedCenter;
			SplinePoints.Add(SplinePoint);
		}
		CirclingSpline.SetPoints(SplinePoints);
		CirclingSpline.Looping = true;
	}

	UFUNCTION()
	void StartSwoopInSequence()
	{
		TListedActors<ASanctuaryCompanionAviationSwoopSequence> SwoopSequences;
		bool bUseLeft = !ActivationParams.bClockwise;
		for (ASanctuaryCompanionAviationSwoopSequence Sequence : SwoopSequences)
		{
			if (Sequence.SequenceType != ESanctuaryCompanionAviationSwoopSequenceType::SwoopIn)
				continue;
			if (Player.IsMio() && Sequence.TargetPlayer == EHazeSelectPlayer::Mio)
			{
				if (Sequence.SequenceDirection == ESanctuaryCompanionAviationSwoopSequenceDirection::TurnLeft && bUseLeft)
					DoTheSequenceThing(Sequence);
				if (Sequence.SequenceDirection == ESanctuaryCompanionAviationSwoopSequenceDirection::TurnRight && !bUseLeft)
					DoTheSequenceThing(Sequence);
			}
			else if (Player.IsZoe() && Sequence.TargetPlayer == EHazeSelectPlayer::Zoe)
			{
				if (Sequence.SequenceDirection == ESanctuaryCompanionAviationSwoopSequenceDirection::TurnLeft && bUseLeft)
					DoTheSequenceThing(Sequence);
				if (Sequence.SequenceDirection == ESanctuaryCompanionAviationSwoopSequenceDirection::TurnRight && !bUseLeft)
					DoTheSequenceThing(Sequence);
			}
		}
	}

	void DoTheSequenceThing(ASanctuaryCompanionAviationSwoopSequence Sequence)
	{
		Player.BlockCapabilities(AviationCapabilityTags::AviationRiding, this);
		if (!DestinationComp.bDevTriggerSwoopInInitAttack)
		{
			// Sequence.SetActorLocation(ActivationParams.PlayerLocation);
			// FQuat FinalRotation = FRotator::MakeFromXZ(ToCenter.GetSafeNormal(), FVector::UpVector).Quaternion() * Sequence.StartWorldRotation;
			FVector ToCenter = CachedCenter - Sequence.ActorLocation;
			ToCenter.Z = 0.0;
			FQuat ToCenterRotation = ToCenter.ToOrientationQuat();
			// FQuat DiffBetweenTargetAndPart = ToCenter * Sequence.StartWorldRotation.Inverse();
			FQuat FinalRotation = Sequence.StartWorldRotation * ToCenterRotation;
			Sequence.SetActorRotation(FinalRotation.Rotator());
		}
		BroadcastShouldPlaySequence(Sequence);
		PlayingSequence = Sequence;
		if (!Sequence.OnDone.IsBound())
			Sequence.OnDone.AddUFunction(this, n"AddPostSwoopInDestinations");
	}

	void BroadcastShouldPlaySequence(ASanctuaryCompanionAviationSwoopSequence Sequence)
	{
		TListedActors<ASanctuaryBossArenaHydraHead> HydraHeads;
		for (ASanctuaryBossArenaHydraHead HydraHead : HydraHeads)
		{
			if (Player.IsSelectedBy(HydraHead.Player))
			{
				// if (HydraHead.LocalHeadState.bDeath)
				// 	continue;
				if (HydraHead.HalfSide == ESanctuaryArenaSideOctant::Left)
					MyLeftHydra = HydraHead;
				if (HydraHead.HalfSide == ESanctuaryArenaSideOctant::Right)
					MyRightHydra = HydraHead;
			}
		}

		if (MyLeftHydra != nullptr)
			MyLeftHydra.SaveLocationBeforeSequencer();
		if (MyRightHydra != nullptr)
			MyRightHydra.SaveLocationBeforeSequencer();

		// PrintToScreen("CLockwise " + ActivationParams.bClockwise + "PLAYING " + Sequence, 10.0);
		Sequence.OnShouldPlaySwoopIn.Broadcast(Player, MegaCompanionComp.MegaCompanion, MyLeftHydra, MyRightHydra);
	}

	UFUNCTION()
	void AddPostSwoopInDestinations()
	{
		if (MyLeftHydra != nullptr)
			MyLeftHydra.LerpBackLocationAfterSequencer();
		if (MyRightHydra != nullptr)
			MyRightHydra.LerpBackLocationAfterSequencer();

		PlayingSequence = nullptr;
	 	// Player.UnblockCapabilities(AviationCapabilityTags::AviationRiding, this);
		while (AviationComp.HasDestination())
			AviationComp.RemoveCurrentDestination(false, this);
		InitAttackDestination();
		AddArenaLandingDestination();
		bQueuedInitAttack = true;
	}

	void InitAttackDestination()
	{
		{ // init attack window
			FSanctuaryCompanionAviationDestinationData SwoopInData;
			TArray<FVector> SplinePoints;
			
			SplinePoints.Add(AviationComp.ToAttackEndLocation);
			float ClosestDistance = CirclingSpline.GetClosestSplineDistanceToLocation(Player.ActorLocation);
			float FirstDistance = ClosestDistance + CirclingSpline.Length * 0.5;
			auto ClosestLocation = CirclingSpline.GetLocationAtDistance(Math::Wrap(FirstDistance, 0.0, CirclingSpline.Length));
			ClosestLocation.Z = AviationComp.ToAttackEndLocation.Z;
			SplinePoints.Add(ClosestLocation);

			SwoopInData.RuntimeSpline.SetPoints(SplinePoints);
			SwoopInData.AviationState = EAviationState::InitAttack;
			AviationComp.AddDestination(SwoopInData);
		}
	}

	void CircleInitAttackDestination()
	{
		{ // init attack window
			FSanctuaryCompanionAviationDestinationData SwoopInData;
			TArray<FVector> SplinePoints;
			
			SplinePoints.Add(Player.ActorLocation);
			float ClosestDistance = CirclingSpline.GetClosestSplineDistanceToLocation(Player.ActorLocation);
			float FirstDistance = ClosestDistance + DistanceStartOffset;
			float DistanceStep = CirclingSpline.Length / 20.0;
			int NumPoints = 6;

			float FloatyPointsRange = NumPoints - 1;
			float PointFraction = 1.0 / FloatyPointsRange;
			int StartingPoint = NumPoints -1;
			for (int iPoint = StartingPoint; iPoint < NumPoints; ++iPoint)
			{
				float AddedDistance = DistanceStep * iPoint;
				auto ClosestLocation = CirclingSpline.GetLocationAtDistance(Math::Wrap(FirstDistance + AddedDistance, 0.0, CirclingSpline.Length));
				float EndHeight = ClosestLocation.Z;
				ClosestLocation.Z = Math::Lerp(Player.ActorLocation.Z, EndHeight, PointFraction * iPoint);
				SplinePoints.Add(ClosestLocation);
			}
			SwoopInData.RuntimeSpline.SetPoints(SplinePoints);
			SwoopInData.AviationState = EAviationState::InitAttack;
			AviationComp.AddDestination(SwoopInData);
		}
	}

	void AddArenaLandingDestination()
	{
		FSanctuaryCompanionAviationDestinationData Data;
		TListedActors<ASanctuaryCompanionAviationLandingPoint> AviationLandingPoints;
		if (AviationLandingPoints.Num() == 0)
			return;
		for (auto LandingPoint : AviationLandingPoints)
		{
			if (WeAreThatPlayer(LandingPoint.Player) && LandingPoint.Side != AviationComp.CurrentQuadrantSide)
			{
				Data.Actor = LandingPoint;
				break;
			}
		}
		Data.bDisableSidescroll = true;
		Data.AviationState = EAviationState::Exit;
		AviationComp.AddDestination(Data);
	}

	bool WeAreThatPlayer(EHazeSelectPlayer TargetedPlayer)
	{
		TArray<AHazePlayerCharacter> SelectedPlayers = Game::GetPlayersSelectedBy(TargetedPlayer);
		return SelectedPlayers.Contains(Player);
	}
};