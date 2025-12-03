
UCLASS(Abstract)
class UWorld_Tundra_Interactable_Fairy_MoveSpline_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnMoveSplineActivated(){}

	UFUNCTION(BlueprintEvent)
	void OnMoveSplineDeactivated(){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION()
	void OnFairyExit()
	{
		bFairyIsOnSpline = false;
		OnFairyExitSpline();
	}

	UFUNCTION()
	void OnFairyEnter()
	{
		bFairyIsOnSpline = true;
		LastDistanceOnSpline = CurrentFairyDistanceOnSpline;
		TimeLeftOnSpline = MAX_flt;
		OnFairyEnterSpline();
	}

	UFUNCTION(BlueprintEvent)
	void OnFairyExitSpline(){}

	UFUNCTION(BlueprintEvent)
	void OnFairyEnterSpline(){}

	ATundraFairyMoveSpline MoveSpline;
	UTundraPlayerFairyComponent FairyComp;
	AHazePlayerCharacter FairyPlayer;

	TArray<FAkSoundPosition> SoundPositions;
	default SoundPositions.SetNum(2);

	UPROPERTY(BlueprintReadWrite)
	bool bFairyIsOnSpline = false;

	UPROPERTY(BlueprintReadWrite, Category = "Exit", Meta = (ForceUnits = "seconds"))
	float ExitEventApexTime = 1.0;

	UPROPERTY(BlueprintReadOnly, Category = "Exit")
	float MoveSplineExitTriggerAlpha = 1.0;

	private float LastDistanceOnSpline = 0.0;
	private float LastTimeOnSpline = 0.0;
	private float TimeLeftOnSpline = 0.0;

	float GetCurrentFairyDistanceOnSpline() const property
	{
		return MoveSpline.Spline.GetClosestSplineDistanceToWorldLocation(FairyPlayer.ActorLocation);
	}
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MoveSpline = Cast<ATundraFairyMoveSpline>(HazeOwner);
		FairyPlayer = Game::GetZoe();
		// FairyComp = UTundraPlayerFairyComponent::Get(FairyPlayer);

		auto AudioComp = DefaultEmitter.GetAudioComponent();	
		AudioComp.SetAttenuationPadding(MoveSpline.Spline.BoundsRadius);

		for(int i = 0; i < 2; ++i)
		{
			SoundPositions[i] = FAkSoundPosition();
		}

		SetSplineEmitterPositions();
		//SetExitTriggerAlphaValue();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		SetSplineEmitterPositions();

		if(bFairyIsOnSpline)
		{
			const float CurrSplineDistance = CurrentFairyDistanceOnSpline;
			const float RemainingSplineDistance = MoveSpline.Spline.SplineLength - CurrSplineDistance;

			const float DistanceDelta = CurrSplineDistance - LastDistanceOnSpline;
			if(DistanceDelta == 0)
			{
				TimeLeftOnSpline = MAX_flt;
				return; 
			}		

			const float RemainingTimeOnSpline = RemainingSplineDistance / (DistanceDelta / DeltaSeconds);

			TimeLeftOnSpline = RemainingTimeOnSpline;
			//PrintToScreenScaled("TimeLeftOnSpline: "+TimeLeftOnSpline);

			LastDistanceOnSpline = CurrentFairyDistanceOnSpline;
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetSplineEmitterPositions()
	{
		int PlayerNum = 0;
		for(auto Player : Game::GetPlayers())
		{
			const FVector PlayerLoc = Player.GetActorLocation();
			const FVector ClosestSplinePos = MoveSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(PlayerLoc);

			SoundPositions[PlayerNum].SetPosition(ClosestSplinePos);
			++PlayerNum;
		}

		auto AudioComp = DefaultEmitter.GetAudioComponent();
		AudioComp.SetMultipleSoundPositions(SoundPositions);
	}

	UFUNCTION(BlueprintPure)
	bool MoveSplineIsActive()
	{
		return MoveSpline.IsMoveSplineActive();
	}

	UFUNCTION(BlueprintPure)
	float GetFairyDistanceAlpha()
	{
		if(!bFairyIsOnSpline)
			return 0.0;

		const FSplinePosition FairySplinePos = MoveSpline.Spline.GetClosestSplinePositionToWorldLocation(FairyPlayer.GetActorLocation());	

		return FairySplinePos.CurrentSplineDistance / MoveSpline.Spline.SplineLength;
	}

	UFUNCTION(BlueprintPure)
	void GetTimeLeftOnSpline(float&out Alpha, float&out SeekTime)
	{
		if(bFairyIsOnSpline)
		{			
			Alpha = TimeLeftOnSpline;
			const float Overshoot = TimeLeftOnSpline - ExitEventApexTime;
			if(Overshoot < 0)
			{
				// Calculate based on max speed
				// const float AvgSpeed = Math::Lerp(DistanceDelta, MoveSpline.MaxSpeed, 0.5);

				// const float MinRemainingTime = RemainingSplineDistance / (DistanceDelta / DeltaTime);
				const float MaxOvershoot = TimeLeftOnSpline - ExitEventApexTime;

				SeekTime = Math::Abs(MaxOvershoot) * 1000;
				//PrintToScreenScaled(""+SeekTime, 1.0);
			}
		}
	}

	private void SetExitTriggerAlphaValue()
	{
		const float DistanceForApex = MoveSpline.MaxSpeed * ExitEventApexTime;
		const float ApexFraction = (MoveSpline.Spline.SplineLength - DistanceForApex) / MoveSpline.Spline.SplineLength;

		MoveSplineExitTriggerAlpha = ApexFraction;
	}
}