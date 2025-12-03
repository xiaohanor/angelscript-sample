struct FSanctuaryCompanionAviationAssignPhase1SwoopBackDestinationActivationParams
{
	FVector PlayerLocation;
}

class USanctuaryCompanionAviationAssignPhase1SwoopBackDestinationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::AviationSequence);
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	UInfuseEssencePlayerComponent InfuseEssenceComp;
	USanctuaryCompanionMegaCompanionPlayerComponent MegaCompanionComp;
	USanctuaryCompanionAviationDestinationComponent DestinationComp;

	FVector CachedCenter;
	FVector PlayerLocation;
	ASanctuaryBossArenaHydra Hydra;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		InfuseEssenceComp = UInfuseEssencePlayerComponent::Get(Player);
		MegaCompanionComp = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Player);
		DestinationComp = USanctuaryCompanionAviationDestinationComponent::GetOrCreate(Player);
		TListedActors<ASanctuaryBossArenaHydra> Hydras;
		if (Hydras.Num() > 0)
			Hydra = Cast<ASanctuaryBossArenaHydra>(Hydras.Single);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryCompanionAviationAssignPhase1SwoopBackDestinationActivationParams& Params) const
	{
		if (HasKilledLastHydra())
			return false;

		if (DestinationComp.bDevTriggerSwoopOutSequence)
		{
			Params.PlayerLocation = Owner.ActorLocation;
			return true;
		}

		if (Player.IsPlayerDead())
			return false;

		if (!AviationComp.bIsRideReady)
			return false;

		if (AviationComp.HasDestination())
			return false;

		if (AviationComp.AviationState != EAviationState::None)
			return false;

		if (!IsActioning(AviationComp.PromptRide.Action) && !AviationDevToggles::Phase1::AutoPromptRiding.IsEnabled())
			return false;
		
		if (!CompanionAviation::bUseLevelSequenceSwoop)
			return false;

		if (Player.GetActiveLevelSequenceActor() != nullptr)
			return false;
		
		Params.PlayerLocation = Owner.ActorLocation;
		return true;
	}

	bool HasKilledLastHydra() const
	{
		if (Hydra == nullptr)
			return false;
		return Hydra.IsDefeated();
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AviationComp.GetIsAviationActive())
			return false;
		if (Player.GetActiveLevelSequenceActor() != nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryCompanionAviationAssignPhase1SwoopBackDestinationActivationParams Params)
	{
		Player.BlockCapabilities(n"Death", this);
		CacheCenter();

		PlayerLocation = Params.PlayerLocation;
		InfuseEssenceComp.ResetOrbs();
		TListedActors<ASanctuaryCompanionAviationSwoopSequence> SwoopSequences;

		AviationComp.UpdateCurrentSide();
		AviationComp.UpdateCurrentOctant();
		UpdatePlayerSequenceLocation();

		bool bTurnLeft = AviationComp.CurrentOctantSide == ESanctuaryArenaSideOctant::Right ? true : false;

		for (ASanctuaryCompanionAviationSwoopSequence Sequence : SwoopSequences)
		{
			if (Sequence.SequenceType != ESanctuaryCompanionAviationSwoopSequenceType::SwoopBack)
				continue;
			if (Player.IsMio() && Sequence.TargetPlayer == EHazeSelectPlayer::Mio)
			{
				if (Sequence.SequenceDirection == ESanctuaryCompanionAviationSwoopSequenceDirection::TurnLeft && bTurnLeft)
					DoTheSequenceThing(Sequence);
				if (Sequence.SequenceDirection == ESanctuaryCompanionAviationSwoopSequenceDirection::TurnRight && !bTurnLeft)
					DoTheSequenceThing(Sequence);
			}
			else if (Player.IsZoe() && Sequence.TargetPlayer == EHazeSelectPlayer::Zoe)
			{
				if (Sequence.SequenceDirection == ESanctuaryCompanionAviationSwoopSequenceDirection::TurnLeft && bTurnLeft)
					DoTheSequenceThing(Sequence);
				if (Sequence.SequenceDirection == ESanctuaryCompanionAviationSwoopSequenceDirection::TurnRight && !bTurnLeft)
					DoTheSequenceThing(Sequence);
			}
		}
		DestinationComp.bDevTriggerSwoopOutSequence = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"Death", this);
	}

	void DoTheSequenceThing(ASanctuaryCompanionAviationSwoopSequence Sequence)
	{
		AviationComp.StartAviation();
		AviationComp.SetAviationState(EAviationState::SwoopingBack);
		Player.BlockCapabilities(AviationCapabilityTags::AviationRiding, this);

		FVector ToCenter = CachedCenter - PlayerLocation;
		ToCenter.Z = 0.0;

		if (DestinationComp.bDevTriggerSwoopOutSequence)
		{
			FVector NewLocation = CachedCenter + GetQuadRimDirection() * ToCenter.Size();
			NewLocation.Z = Player.ActorLocation.Z;
			Sequence.SetActorLocation(NewLocation);
		}
		else
			Sequence.SetActorLocation(PlayerLocation);

		Sequence.SetActorRotation(FRotator::MakeFromXZ(ToCenter.GetSafeNormal(), FVector::UpVector));
		Sequence.OnShouldPlay.Broadcast(Player, MegaCompanionComp.MegaCompanion);
		if (!Sequence.OnDone.IsBound())
			Sequence.OnDone.AddUFunction(this, n"BuildDestinations");
	}

	UFUNCTION()
	private void BuildDestinations()
	{
		BuildToAttackSpline();
		Player.UnblockCapabilities(AviationCapabilityTags::AviationRiding, this);
	}

	UFUNCTION()
	private void BuildToAttackSpline()
	{
		FVector BetweenHydrasLocation;
		{	
			TListedActors<ASanctuaryBossArenaHydra> Hydras;
			for (auto Head : Hydras.Single.HydraHeads)
			{
				if (Head.TargetPlayer == Player)
				{
					BetweenHydrasLocation.X = Head.ActorLocation.X;
					BetweenHydrasLocation.Y = Head.ActorLocation.Y;
					break;
				}
			}
		}

		FVector BetweenHydrasAtSpecificHeight = BetweenHydrasLocation;
		BetweenHydrasAtSpecificHeight.Z = CachedCenter.Z + AviationComp.Settings.ToAttackHeight;
		FVector CenterAtHeight = CachedCenter;
		CenterAtHeight.Z += AviationComp.Settings.ToAttackHeight;

		FVector FromHydraToPlayer = Player.ActorLocation - BetweenHydrasAtSpecificHeight;
		FromHydraToPlayer.Z = 0.0;

		FVector ToRimDirection = GetQuadRimDirection();
		float ToAttackLength = AviationComp.Settings.ToAttackDistanceStart - AviationComp.Settings.ToAttackDistanceStopBeforeHydra;
		FVector ToAttackStartLocation = BetweenHydrasAtSpecificHeight + ToRimDirection * ToAttackLength;
		FVector ToAttackEndLocation = CachedCenter; //GetSwoopInSequenceLocation();
		ToAttackEndLocation += ToRimDirection * AviationComp.Settings.ToAttackDistanceStopBeforeHydra;
		ToAttackEndLocation.Z = ToAttackStartLocation.Z;

		AviationComp.ToAttackEndLocation = ToAttackEndLocation;
		{ // swoopeti back
			FSanctuaryCompanionAviationDestinationData SwoopBackData;
			TArray<FVector> SplinePoints;
			SplinePoints.Add(MegaCompanionComp.MegaCompanion.ActorLocation);
			SplinePoints.Add(ToAttackStartLocation);
			SwoopBackData.RuntimeSpline.SetPoints(SplinePoints);
			SwoopBackData.AviationState = EAviationState::SwoopingBack;
			SwoopBackData.bLerp = true;
			AviationComp.AddDestination(SwoopBackData);
		}

		{ // to attack
			FSanctuaryCompanionAviationDestinationData Data;
			TArray<FVector> SplinePoints;
			SplinePoints.Add(ToAttackStartLocation);
			SplinePoints.Add(ToAttackEndLocation);
			Data.RuntimeSpline.SetPoints(SplinePoints);
			TArray<FVector> Ups;
			Ups.Add(FVector::UpVector);
			Ups.Add(FVector::UpVector);
			Data.RuntimeSpline.SetUpDirections(Ups);
			Data.RuntimeSpline.SetCustomEnterTangentPoint(-ToRimDirection);
			Data.RuntimeSpline.SetCustomExitTangentPoint(ToRimDirection);
			Data.AviationState = EAviationState::ToAttack;
			AviationComp.AddDestination(Data);
		}

		{ // swoop in
			FSanctuaryCompanionAviationDestinationData Data;
			TArray<FVector> SplinePoints;
			SplinePoints.Add(ToAttackEndLocation);
			SplinePoints.Add(CenterAtHeight);
			Data.RuntimeSpline.SetPoints(SplinePoints);
			Data.AviationState = EAviationState::SwoopInAttack;
			AviationComp.AddDestination(Data);
		}
	}

	FVector GetSwoopInSequenceLocation()
	{
		TListedActors<ASanctuaryCompanionAviationSwoopSequence> SwoopSequences;
		for (ASanctuaryCompanionAviationSwoopSequence Sequence : SwoopSequences)
		{
			if (Sequence.SequenceType != ESanctuaryCompanionAviationSwoopSequenceType::SwoopIn)
				continue;
			if (Player.IsMio() && Sequence.TargetPlayer == EHazeSelectPlayer::Mio)
				return Sequence.ActorLocation;
			else if (Player.IsZoe() && Sequence.TargetPlayer == EHazeSelectPlayer::Zoe)
				return Sequence.ActorLocation;
		}
		return FVector();
	}

	private FVector GetQuadRimDirection()
	{
		float Sign = AviationComp.CurrentQuadrantSide == ESanctuaryArenaSide::Right ? 1.0 : -1.0;
		if (Player.IsMio())
			return FVector::RightVector * Sign;
		return FVector::ForwardVector * Sign;
	}

	void CacheCenter()
	{
		TListedActors<ASanctuaryBossArenaManager> ArenaOrigoActor;
		check(ArenaOrigoActor.Num() == 1, "More or less than one ASanctuaryBossArenaManager found!");
		ASanctuaryBossArenaManager ArenaManager = ArenaOrigoActor[0];
		CachedCenter = ArenaManager.ActorLocation;
	}

	void UpdatePlayerSequenceLocation()
	{
		TListedActors<ASanctuaryCompanionAviationSwoopSequence> SwoopSequences;
		for (ASanctuaryCompanionAviationSwoopSequence Sequence : SwoopSequences)
		{
			if (Sequence.SequenceType != ESanctuaryCompanionAviationSwoopSequenceType::SwoopIn)
				continue;
			if (Player.IsMio() && Sequence.TargetPlayer == EHazeSelectPlayer::Mio)
				UpdateSequenceLocation(Sequence);
			else if (Player.IsZoe() && Sequence.TargetPlayer == EHazeSelectPlayer::Zoe)
				UpdateSequenceLocation(Sequence);
		}
	}

	void UpdateSequenceLocation(ASanctuaryCompanionAviationSwoopSequence Sequence)
	{
		FVector DesiredSequenceOffsetDirection = GetQuadRimDirection();
		FVector CurrentOffsetFromCenter = Sequence.ActorLocation - CachedCenter;
		FVector CurrentSequenceDirection = CurrentOffsetFromCenter;
		CurrentSequenceDirection.Z = 0.0;
		
		FQuat DiffBetweenTargetAndPart = DesiredSequenceOffsetDirection.ToOrientationQuat() * CurrentSequenceDirection.ToOrientationQuat().Inverse();
		FVector NewOffsetFromCenter = DiffBetweenTargetAndPart.RotateVector(CurrentOffsetFromCenter);

		Sequence.SetActorLocation(CachedCenter + NewOffsetFromCenter);
		Sequence.SetActorRotation(FRotator::MakeFromXZ(-DesiredSequenceOffsetDirection, FVector::UpVector));
		// Debug::DrawDebugSphere(Sequence.ActorLocation, 200.0, 12, ColorDebug::Magenta, 5.0, 10.0);
		// Debug::DrawDebugCoordinateSystem(Sequence.ActorLocation, Sequence.ActorRotation, 500.0, 5.0, 10.0);
	}
};