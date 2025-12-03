enum EMaxSecurityLaserBehaviour
{
	None,
	Spline,
	SplineTimelike,
	RotatingConstant,
	RotatingBackForth
}

struct FLaserTrackedPlayerPosition
{
	float ClosestDistance;
	FVector TargetPoint;
	FVector InterpPos;
}


UCLASS(Abstract)
class UWorld_Prison_MaxSecurity_Spot_MaxSecurityLaser_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnReachSplineEnd(FMaxSecurityLaserSplineParams SplineParams){}

	UFUNCTION(BlueprintEvent)
	void OnStartOnSpline(FMaxSecurityLaserSplineParams SplineParams){}

	UFUNCTION(BlueprintEvent)
	void SetupLaser(FMaxSecurityLaserSetupParams SetupParams){}

	UFUNCTION(BlueprintEvent)
	void OnLaserStartMoveIn(FMaxSecurityLaserSetupParams SetupParams){}

	UFUNCTION(BlueprintEvent)
	void OnLaserStartMoveOut(FMaxSecurityLaserSetupParams SetupParams){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	AMaxSecurityLaser Laser;

	UPROPERTY()
	int32 LaserCount;

	// Used to make sure that lasers on splines can't trigger passby if their remaining spline distance is to short, since they will make a jump when they reach it
	UPROPERTY()
	float RemainingSplineDistancePassbyThreshold = 0;

	UPROPERTY()
	EMaxSecurityLaserBehaviour Behaviour = EMaxSecurityLaserBehaviour::None;

	UPROPERTY()
	UHazeAudioEvent LaserLoopEvent;

	UPROPERTY()
	UHazeAudioEvent LaserMoveInEvent;

	UPROPERTY()
	UHazeAudioEvent LaserMoveOutEvent;

	UPROPERTY()
	UHazeAudioEvent LaserPassbyEvent;

	private TArray<FAkSoundPosition> SoundPositions;

	FVector LastClosestMioPos;
	FVector LastClosestZoePos;

	TArray<AHazePlayerCharacter> Players;

	TPerPlayer<FLaserTrackedPlayerPosition> DistancePlayerData;
	TPerPlayer<FLaserTrackedPlayerPosition> PreviousDistancePlayerData;
	bool bPositionInitialized = false;

	TArray<FAkSoundPosition> LaserPositions;

	const float MULTIPLE_POSITIONS_INTERP_SPEED = 5.0;
	// just for safety.
	private bool bReactivated = false;

	UFUNCTION(BlueprintEvent)
	void OnLaserStart() {};

	UFUNCTION(BlueprintEvent)
	void SetupRotatingLaser() {};

	UFUNCTION(BlueprintEvent)
	void SetupSplineTimelike() {};

	UFUNCTION(BlueprintEvent)
	void SetupSplineMovement() {};

	UFUNCTION(BlueprintPure)
	bool CanPlaySplinePassby()
	{
		if(Laser == nullptr || Laser.HasSpline())
			return false;

		UHazeSplineComponent SplineComp = Laser.GetSpline();
		const float RemainingsSplineDistance = SplineComp.SplineLength - Laser.GetCurrentSplineDistance();

		return RemainingsSplineDistance > RemainingSplineDistancePassbyThreshold;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bReactivated = true;

		// If activating again after being disabled we need to start the loop in BP
		if(!bFirstActivation && Laser != nullptr)
			OnLaserStart();
	}

	UFUNCTION(BlueprintCallable)
	void ParentSetupLaser(AMaxSecurityLaser InLaser)
	{
		// Don't run the setup twice, and loop (starts by OnLaserStart)
		if (InLaser == Laser)
			return;

		Laser = InLaser;
		if(Laser == nullptr)
			return;

		LaserCount = Laser.LaserCount;
		SetLaserBehaviour();

		if(Behaviour == EMaxSecurityLaserBehaviour::RotatingBackForth)
			SetupRotatingLaser();		

		else if(Behaviour == EMaxSecurityLaserBehaviour::SplineTimelike)
			SetupSplineTimelike();

		else if(Behaviour == EMaxSecurityLaserBehaviour::Spline)
			SetupSplineMovement();

		Players = Game::GetPlayers();		

		if(Laser.AudioVolume != nullptr)
		{			
			int NumLaserPositions = Laser.AudioVolume.LasersInBounds.Num() * ((Laser.AudioVolume.TrackPlayers[Game::GetMio()] ? 1 : 0) + (Laser.AudioVolume.TrackPlayers[Game::GetZoe()] ? 1 : 0));
			LaserPositions.SetNum(NumLaserPositions);

			for(auto& Player : Players)
			{
				if(Laser.AudioVolume.TrackPlayers[Player])
					SoundPositions.Add(FAkSoundPosition(FVector()));
			}

			LaserCount = Laser.AudioVolume.LasersInBounds.Num();		

			if(Laser.AudioVolume.LoopEvent != nullptr)
				LaserLoopEvent = Laser.AudioVolume.LoopEvent;

			if(Laser.AudioVolume.MoveInEvent != nullptr)
				LaserMoveInEvent = Laser.AudioVolume.MoveInEvent;

			if(Laser.AudioVolume.MoveOutEvent != nullptr)
				LaserMoveOutEvent = Laser.AudioVolume.MoveOutEvent;

			if(Laser.AudioVolume.PassbyEvent != nullptr)
				LaserPassbyEvent = Laser.AudioVolume.PassbyEvent;
		}

		bPositionInitialized = true;
		OnLaserStart();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (Laser == nullptr)
		{
			// Hacky way of making sure that RootLaser has time to initialize itself - copied from AMaxSecurityLaserAudioVolume
			// I don't know if it's valid anymore.
			if (bReactivated && TimeActive > 0.1)
			{
				auto LaserOwner = Cast<AMaxSecurityLaser>(HazeOwner);
				SetupLaser(FMaxSecurityLaserSetupParams(LaserOwner));
				bReactivated = false;
			}
			return;
		}

		if(Laser.AudioVolume == nullptr)
			return;

		auto LaserVolume = Laser.AudioVolume;	
		auto Mio = Game::GetMio();
		auto Zoe = Game::GetZoe();

		int LaserPositionIndex = 0;
		for(int i = 0; i < Laser.AudioVolume.LasersInBounds.Num(); ++i)
		{
			AMaxSecurityLaser ItLaser = Laser.AudioVolume.LasersInBounds[i];
			if(ItLaser == nullptr)
				continue;

			if(LaserVolume.TrackPlayers[Mio])
			{
				const FVector MioPos  = Mio.GetActorCenterLocation();		
				const FVector MioPlayerPoint = Math::ClosestPointOnLine(ItLaser.LaserComp.CurrentBeamStartLoc, ItLaser.LaserComp.CurrentBeamEndLoc, MioPos);
				LaserPositions[LaserPositionIndex].SetPosition(MioPlayerPoint);

				++LaserPositionIndex;

			}
			if(LaserVolume.TrackPlayers[Zoe])
			{
				const FVector ZoePos  = Zoe.GetActorCenterLocation();		
				const FVector ZoePlayerPoint = Math::ClosestPointOnLine(ItLaser.LaserComp.CurrentBeamStartLoc, ItLaser.LaserComp.CurrentBeamEndLoc, ZoePos);
				LaserPositions[LaserPositionIndex].SetPosition(ZoePlayerPoint);

				++LaserPositionIndex;
			}		
		}					

		// int32 SoundPosIt = 0;
		// for(auto& Player : Players)
		// {
		// 	if(Laser.AudioVolume.TrackPlayers[Player])
		// 	{
		// 		DistancePlayerData[Player].InterpPos = Math::VInterpTo(PreviousDistancePlayerData[Player].InterpPos, DistancePlayerData[Player].TargetPoint, DeltaSeconds, MULTIPLE_POSITIONS_INTERP_SPEED);
		// 		SoundPositions[SoundPosIt] = FAkSoundPosition(DistancePlayerData[Player].InterpPos);
		// 		//Debug::DrawDebugPoint(SoundPositions[SoundPosIt].Position, 10, FLinearColor::LucBlue, bRenderInForground = true);				
		// 		++SoundPosIt;

		// 		PreviousDistancePlayerData[Player].ClosestDistance = DistancePlayerData[Player].ClosestDistance;
		// 		PreviousDistancePlayerData[Player].TargetPoint = DistancePlayerData[Player].TargetPoint;
		// 		PreviousDistancePlayerData[Player].InterpPos = DistancePlayerData[Player].InterpPos;
		// 	}
		// }

		if(bPositionInitialized)
			DefaultEmitter.AudioComponent.SetMultipleSoundPositions(LaserPositions);
		//PrintToScreenScaled(""+Laser.RotationTimeLike.Value);
	}	

	private void SetLaserBehaviour()
	{
		if(Laser == nullptr)
			return;

		bool bForceUseRotation = false;	
		if(Laser.AudioVolume != nullptr)
		{
			bForceUseRotation = Laser.AudioVolume.bForceUseRotation;
		}

		if(!bForceUseRotation && Laser.HasSpline())
		{
			if(Laser.SplineMovement == EMaxSecurityLaserSplineMovement::Curve)			
				Behaviour = EMaxSecurityLaserBehaviour::SplineTimelike;
			else
				Behaviour = EMaxSecurityLaserBehaviour::Spline;

		}
		else if(!Laser.ConstantRotationRate.IsZero())
		{
			Behaviour = EMaxSecurityLaserBehaviour::RotatingConstant;
		}
		else if(!Laser.TargetRotation.IsZero())
		{
			Behaviour = EMaxSecurityLaserBehaviour::RotatingBackForth;
		}		
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentRotationValue(const float&in ErrorTolerance) const
	{
		auto Value = Laser.GetCurrentRotationCurveValue();
		// Fix value jiterring up and down around zero
		if (Math::IsNearlyZero(Value, ErrorTolerance))
			return 0;

		return Value;
	}
}