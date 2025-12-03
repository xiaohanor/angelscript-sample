struct FSanctuaryCompanionAviationAssignTutorialDestinationActivationParams
{
	FVector SequenceTargetLocation;
	FQuat SequenceTargetRotation;
}

class USanctuaryCompanionAviationAssignTutorialDestinationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	UInfuseEssencePlayerComponent InfuseEssenceComp;
	USanctuaryCompanionMegaCompanionPlayerComponent MegaCompanionComp;

	FSanctuaryCompanionAviationAssignTutorialDestinationActivationParams ActivationParams;
	
	bool bDevTrigger = false;
	bool bQueuedSpline = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		InfuseEssenceComp = UInfuseEssencePlayerComponent::Get(Player);
		MegaCompanionComp = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Player);
	}

	UFUNCTION(DevFunction)
	void DevTriggerSwoopSequence()
	{
		bDevTrigger = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryCompanionAviationAssignTutorialDestinationActivationParams& Params) const
	{
		if (bDevTrigger)
		{
			AssignLocationRotation(Params);
			return true;
		}

		if (!AviationComp.bIsRideReady)
			return false;

		if (AviationComp.HasDestination())
			return false;

		if (!IsActioning(AviationComp.PromptRide.Action))
			return false;

		AssignLocationRotation(Params);
		return true;
	}

	private void AssignLocationRotation(FSanctuaryCompanionAviationAssignTutorialDestinationActivationParams& Params) const
	{
		TListedActors<ASanctuaryCompanionAviationSwoopSequence> SwoopSequences;
		for (ASanctuaryCompanionAviationSwoopSequence Sequence : SwoopSequences)
		{
			if (Player.IsSelectedBy(Sequence.TargetPlayer))
			{
				Params.SequenceTargetLocation = Sequence.ActorLocation;
				Params.SequenceTargetRotation = Sequence.ActorRotation.Quaternion();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bQueuedSpline)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryCompanionAviationAssignTutorialDestinationActivationParams Params)
	{
		InfuseEssenceComp.ResetOrbs();
		bDevTrigger = false;
		bQueuedSpline = false;
		ActivationParams = Params;
		Player.BlockCapabilities(AviationCapabilityTags::AviationRiding, this);
		bool bSequenceSuccess = TryPlayTutorialSequence();
		if (!bSequenceSuccess)
			NewTutorial();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(AviationCapabilityTags::AviationRiding, this);
	}

	bool TryPlayTutorialSequence()
	{
		TListedActors<ASanctuaryCompanionAviationSwoopSequence> SwoopSequences;
		for (ASanctuaryCompanionAviationSwoopSequence Sequence : SwoopSequences)
		{
			if (Player.IsMio() && Sequence.TargetPlayer == EHazeSelectPlayer::Mio)
				return DoTheSequenceThing(Sequence);
			else if (Player.IsZoe() && Sequence.TargetPlayer == EHazeSelectPlayer::Zoe)
				return DoTheSequenceThing(Sequence);
		}
		return false;
	}

	bool DoTheSequenceThing(ASanctuaryCompanionAviationSwoopSequence Sequence)
	{
		AviationComp.StartAviation();

		Sequence.SetActorLocation(ActivationParams.SequenceTargetLocation);
		Sequence.SetActorRotation(ActivationParams.SequenceTargetRotation);
		Sequence.OnShouldPlay.Broadcast(Player, MegaCompanionComp.MegaCompanion);
		if (!Sequence.OnDone.IsBound())
			Sequence.OnDone.AddUFunction(this, n"NewTutorial");
		return true;
	}

	UFUNCTION()
	private void NewTutorial()
	{
		TListedActors<ASanctuaryAviationTutorialSpline> TutorialSplines;
		// if (TutorialSplines.Num() == 0)
		// {
		// 	OldTutorial();
		// }
		// else
		{
			for (auto Spliney : TutorialSplines)
			{
				if (Player.IsMio() && Spliney.SelectedPlayer == EHazeSelectPlayer::Mio)
					AddSplineDestination(Spliney);
				if (Player.IsZoe() && Spliney.SelectedPlayer == EHazeSelectPlayer::Zoe)
					AddSplineDestination(Spliney);
			}
		}
		bQueuedSpline = true;
	}

	private void AddSplineDestination(ASanctuaryAviationTutorialSpline Spliney)
	{
		TArray<FVector> SplinePoints;
		SplinePoints.Add(Player.ActorLocation);

		FHazeRuntimeSpline RuntimeSpliney = Spliney.Spline.BuildRuntimeSplineFromHazeSpline();

		// between player position and runtime spine first point, 
		// to get some distribution for the runtime spline <3
		// {
		// 	float SplinePointLengthStep = Spliney.Spline.SplineLength / 40.0;
		// 	FVector FirstPoint = RuntimeSpliney.Points[0];
		// 	FVector TowardsFirst = FirstPoint - Player.ActorLocation;
		// 	FVector TowardsFirstLocation = TowardsFirst.GetSafeNormal();
		// 	float FloatSteps = TowardsFirst.Size() / SplinePointLengthStep;
		// 	int IntSteps = Math::FloorToInt(FloatSteps);
		// 	for (int i = 0; i < IntSteps; ++i)
		// 	{
		// 		FVector AddedStep = TowardsFirstLocation * SplinePointLengthStep * i;
		// 		SplinePoints.Add(Player.ActorLocation + AddedStep);
		// 	}
		// }

		for (int iPoint = 0; iPoint < RuntimeSpliney.Points.Num(); iPoint++)
			SplinePoints.Add(RuntimeSpliney.Points[iPoint]);

		FSanctuaryCompanionAviationDestinationData Data;
		Data.RuntimeSpline.SetPoints(SplinePoints);
		Data.AviationState = EAviationState::ToAttack;
		AviationComp.AddDestination(Data);
	}

	void OldTutorial()
	{
		TListedActors<ASanctuaryCompanionAviationLandingPoint> AviationLandingPoints;
		if (AviationLandingPoints.Num() == 0)
			return;

		bool bUseSplineMovement = true;
		if (bUseSplineMovement)
		{
			TArray<FVector> SplinePoints;
			SplinePoints.Add(Owner.ActorLocation);
			SplinePoints.Add(AviationLandingPoints.Single.ActorLocation);
			FSanctuaryCompanionAviationDestinationData Data;
			Data.RuntimeSpline.SetPoints(SplinePoints);
			Data.AviationState = EAviationState::ToAttack;
			AviationComp.AddDestination(Data);
		}
		else
		{
			FSanctuaryCompanionAviationDestinationData Data;
			Data.Actor = AviationLandingPoints.Single;
			AviationComp.AddDestination(Data);
		}
	}
};