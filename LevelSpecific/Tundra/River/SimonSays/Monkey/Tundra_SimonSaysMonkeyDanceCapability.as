// class UTundra_SimonSaysMonkeyDanceCapability : UHazeCapability
// {
// 	default TickGroup = EHazeTickGroup::ActionMovement;
// 	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

// 	FTundra_SimonSaysSequence CurrentSequence;

// 	ATundra_SimonSaysMonkey Monkey;
// 	UTundra_SimonSaysMonkeySettings Settings;
// 	UHazeMovementComponent MoveComp;
// 	UTeleportingMovementData Movement;
// 	ATundra_SimonSaysManager Manager;
// 	AHazePlayerCharacter MirroringPlayer;

// 	bool bDone = false;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		Monkey = Cast<ATundra_SimonSaysMonkey>(Owner);
// 		Settings = UTundra_SimonSaysMonkeySettings::GetSettings(Owner);
// 		Manager = TundraSimonSays::GetManager();
// 		MoveComp = Monkey.MoveComp;
// 		Movement = MoveComp.SetupTeleportingMovementData();
// 		MirroringPlayer = Game::GetPlayer(Monkey.MirroringPlayer);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate(FTundra_SimonSaysMonkeyMoveToPointActivatedParams& Params) const
// 	{
// 		if(!Manager.IsOnMonkeyMeasure())
// 			return false;

// 		int DanceSequenceIndex = Manager.GetCurrentDanceSequenceIndex();

// 		Params.DanceSequenceIndex = DanceSequenceIndex;
// 		return true;
// 	}
	
// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		if(bDone)
// 			return true;

// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FTundra_SimonSaysMonkeyMoveToPointActivatedParams Params)
// 	{
// 		Manager.GetDanceSequenceForPlayer(MirroringPlayer, Params.DanceSequenceIndex, CurrentSequence);
// 		bDone = false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		Monkey.CurrentPointIndex = CurrentSequence.Sequence[Manager.BeatsPerMeasure - 1];
// 		Monkey.AnimData.bIsJumping = false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if(MoveComp.PrepareMove(Movement))
// 		{
// 			if(HasControl())
// 			{
// 				float Alpha = Manager.GetCurrentMeasureAlpha();
// 				if(Math::IsNearlyEqual(Alpha, 1.0) || !Manager.IsOnMonkeyMeasure())
// 				{
// 					Alpha = 1.0;
// 					bDone = true;
// 				}

// 				int OriginSeqIndex = GetOriginSequenceIndex(Alpha);

// 				int OriginIndex = OriginSeqIndex < 0 ? Monkey.CurrentPointIndex : CurrentSequence.Sequence[OriginSeqIndex];
// 				int DestinationIndex = CurrentSequence.Sequence[OriginSeqIndex + 1];

// 				FVector Origin;
// 				Origin = Manager.GetPointForMonkey(MirroringPlayer, OriginIndex).ActorLocation;
// 				FVector Destination = Manager.GetPointForMonkey(MirroringPlayer, DestinationIndex).ActorLocation;

// 				float DanceStepMoveAlpha = GetDanceStepMoveAlpha(Alpha);

// 				Monkey.AnimData.bIsJumping = DanceStepMoveAlpha != 1.0 && DanceStepMoveAlpha != 0.0;
// 				Monkey.AnimData.JumpAlpha = DanceStepMoveAlpha;

// 				FVector CurrentLocation = BezierCurve::GetLocation_2CP_ConstantSpeed(Origin, Origin + FVector::UpVector * Monkey.BezierControlPointHeight, Destination + FVector::UpVector * Monkey.BezierControlPointHeight, Destination, DanceStepMoveAlpha);

// 				Movement.AddDelta(CurrentLocation - Monkey.ActorLocation);
// 				Movement.InterpRotationTo(FQuat::MakeFromZX(FVector::UpVector, (Destination - Origin)), Settings.TurnRate);
// 			}
// 			else
// 			{
// 				Movement.ApplyCrumbSyncedAirMovement();
// 			}

// 			MoveComp.ApplyMove(Movement);
// 		}
// 	}

// 	int GetOriginSequenceIndex(float Alpha)
// 	{
// 		int OriginSeqIndex = Math::FloorToInt(Alpha / (1.0 / Manager.BeatsPerMeasure)) - 1;
// 		OriginSeqIndex = Math::Min(Manager.BeatsPerMeasure - 2, OriginSeqIndex);

// 		return OriginSeqIndex;
// 	}

// 	float GetDanceStepMoveAlpha(float Alpha)
// 	{
// 		float AlphaDanceMoveFraction = 1.0 / Manager.BeatsPerMeasure;

// 		// Fmod is modulo but a bit more precise when working with floats.
// 		float DanceMoveAlpha = Math::Fmod(Alpha, AlphaDanceMoveFraction) / AlphaDanceMoveFraction;

// 		// When we are done the alpha may have wrapped around to 0 if we entered the next measure, so set it to 1
// 		if(bDone)
// 			DanceMoveAlpha = 1.0;

// 		return DanceMoveAlpha;
// 	}
// }

// struct FTundra_SimonSaysMonkeyMoveToPointActivatedParams
// {
// 	int DanceSequenceIndex;
// }