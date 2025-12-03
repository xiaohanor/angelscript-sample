namespace PlayerLadderClimb
{
	const FConsoleVariable CVar_DebugLadders("Haze.Movement.Debug.Ladders", 0);
}

class UPlayerLadderComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UPlayerLadderSettings Settings;

	UPROPERTY(Category = "Settings | FF")
	UForceFeedbackEffect DashFF;

	UPROPERTY(Category = "Settings | FF")
	UForceFeedbackEffect EnterFF;

	UPROPERTY(Category = "Settings | FF")
	UForceFeedbackEffect JumpOutFF;

	UPROPERTY(Category = "Settings | Camera")
	FRuntimeFloatCurve TopEnterCameraOffsetBlendOutCurve;

	UPROPERTY(Category = "Settings | Camera")
	FRuntimeFloatCurve TopEnterCameraOffsetBlendInCurve;

	bool bEnteredFromWallrun = false;
	bool bTriggerExitOnTop = false;
	float EnterAngle;
	float LadderCooldown = 0.5;
	float LadderCooldownCurr;

	bool bDisableClimbingUpUntilReInput = false;
	bool bDisableClimbingDownUntilReInput = false;

	protected EPlayerLadderState CurrentState = EPlayerLadderState::Inactive;
	FPlayerLadderData Data;
	FPlayerLadderAnimData AnimData;
	
	UPROPERTY()
	private ALadder TrackedCooldownLadder;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Player);
		Settings = UPlayerLadderSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(LadderCooldownCurr <= LadderCooldown)
		{
			LadderCooldownCurr += DeltaSeconds;
		}
		else if(State == EPlayerLadderState::Inactive && TrackedCooldownLadder != nullptr)
			TrackedCooldownLadder = nullptr;

#if EDITOR 
		if(PlayerLadderClimb::CVar_DebugLadders.GetInt() == 0)
			return;

		PrintToScreen("LadderCD: "+LadderCooldownCurr, 0.0);
		PrintToScreen("TrackedLadder: " + TrackedCooldownLadder);
		PrintToScreen(""+AnimData.State, 0.0);
		PrintToScreen(""+ Data.QueryLadderData.Num(), 0.0);

		if (Data.ActiveLadder != nullptr)
		{
			FLadderRung ClosestRung = Data.ActiveLadder.GetClosestRungToWorldLocation(Player.ActorLocation);
			FVector RungLocation = Data.ActiveLadder.GetRungWorldLocation(ClosestRung);
			if ((RungLocation - Player.ActorLocation).Size() < 1.0)
			{
				Debug::DrawDebugSphere(Player.ActorLocation, 20.0, 12, FLinearColor::Green);
				return;
			}
			Debug::DrawDebugSphere(RungLocation, 20.0);
			Debug::DrawDebugSphere(Player.ActorLocation, 20.0, 12, FLinearColor::LucBlue);
		}
#endif
	}

	void UpdateClosestQueryRung()
	{
		Data.QueryClosestRung = Data.TargetLadderData.Ladder.GetClosestRungToWorldLocation(Player.ActorLocation);
	}

	void ActivateLadderClimb(ALadder Ladder)
	{
		if (Data.ActiveLadder != nullptr)
			return;

		bTriggerExitOnTop = false;
		Data.ActiveLadder = Ladder;
		TrackedCooldownLadder = Ladder;
		Data.ActiveLadder.Interact.DisableForPlayer(Player, this);
	}

	void DeactivateLadderClimb()
	{
		if (Data.ActiveLadder == nullptr)
			return;

		Data.ActiveLadder.Interact.EnableForPlayer(Player,this);
		Data.ActiveLadder = nullptr;

		Data.ResetData();

		ResetLadderCooldown();
	}

	void SetEnterAngle(FVector StartLoc, FVector EndLoc)
	{
		FVector DirToPlayer = (EndLoc - StartLoc).GetSafeNormal2D();
		float Dot = (Data.ActiveLadder.ActorForwardVector * 1.0).DotProduct(DirToPlayer);
		float Deg = Math::Acos(Dot);
		Deg = Math::RadiansToDegrees(Deg);

		if (DirToPlayer.DotProduct(Data.ActiveLadder.ActorRightVector) > 0)
			Deg *= -1.0;

		EnterAngle = Deg;
	}

	void ResetLadderCooldown()
	{
		LadderCooldownCurr = 0.0;
	}

	bool OnLadderCooldown() const
	{
		if (LadderCooldownCurr < LadderCooldown && TrackedCooldownLadder == Data.TargetLadderData.Ladder)
			return true;
		else
			return false;
	}

	//Will return true if player is in any climbing state except exits
	bool IsClimbing() const
	{
		return (GetState() != EPlayerLadderState::Inactive &&
				 GetState() != EPlayerLadderState::JumpOut &&
				  GetState() != EPlayerLadderState::LetGo &&
				   GetState() != EPlayerLadderState::ExitOnBottom &&
				    GetState() != EPlayerLadderState::ExitOnTop &&
					 GetState() != EPlayerLadderState::TransferUp &&
					  GetState() != EPlayerLadderState::TransferDown);
	}

	EPlayerLadderState GetState() const property
	{
		return CurrentState;
	}

	void SetState(EPlayerLadderState NewState) property
	{
		CurrentState = NewState;
		AnimData.State = NewState;
	}

	// Returns true if the state completed was the active state (nothing else took over) and resets data
	bool VerifyExitStateCompleted(EPlayerLadderState CompletedState)
	{
		if (State == CompletedState)
		{
			SetState(EPlayerLadderState::Inactive);
			ResetLadderData();
			return true;
		}
		return false;
	}

	void ResetLadderData()
	{
		Data.ResetData();
		AnimData.ResetData();
		SetState(EPlayerLadderState::Inactive);
	}

	bool TestForValidEnter()
	{
		if (Data.QueryLadderData.Num() == 0)
		{
			Data.TargetLadderData.Ladder = nullptr;
			return false;
		}
		
		FQueryLadderData TopScoredLadder;

		if(Data.QueryLadderData.Num() == 1)
		{
			float PlayerToPoleVerticalDelta = (Data.QueryLadderData[0].Ladder.ActorLocation - Player.ActorLocation).ConstrainToPlane(Player.ActorForwardVector).Size() * Math::Sign((Data.QueryLadderData[0].Ladder.ActorLocation - Player.ActorLocation).DotProduct(MoveComp.WorldUp));
			if(PlayerToPoleVerticalDelta <= 82 || Data.QueryLadderData[0].bForceEntry)
				TopScoredLadder = Data.QueryLadderData[0];
		}
		else
		{
			FVector PlayerToLadderHorizontalDelta;
			float ClosestDistance = 0;

			for(int i = 0; i < Data.QueryLadderData.Num(); i++)
			{
				//Go through each ladder and if its closer then the first ladder we tested then set it as top scoring ladder
				PlayerToLadderHorizontalDelta = (Data.QueryLadderData[i].Ladder.ActorLocation - Player.ActorLocation).ConstrainToPlane(Player.MovementWorldUp);
				
				//Verify that its within height cutoff (half capsule height)
				float PlayerToPoleVerticalDelta = (Data.QueryLadderData[i].Ladder.ActorLocation - Player.ActorLocation).ConstrainToPlane(Player.ActorForwardVector).Size() * Math::Sign((Data.QueryLadderData[i].Ladder.ActorLocation - Player.ActorLocation).DotProduct(MoveComp.WorldUp));

				if(i == 0 || (PlayerToLadderHorizontalDelta.Size() < ClosestDistance && PlayerToPoleVerticalDelta <= 82) || Data.QueryLadderData[0].bForceEntry)
				{
					ClosestDistance = PlayerToLadderHorizontalDelta.Size();
					TopScoredLadder = Data.QueryLadderData[i];
				}
			}
		}

		if(TopScoredLadder.Ladder == nullptr)
			return false;

		Data.TargetLadderData = TopScoredLadder;
		UpdateClosestQueryRung();
		return true;
	}

	bool TestForValidTopEnter()
	{
		if(Data.QueryTopEnterLadders.Num() == 0 && Data.EnterFromTopLadder == nullptr) 
		{
			return false;
		}

		if (Data.EnterFromTopLadder != nullptr)
			return true;

		if (MoveComp.MovementInput.IsNearlyZero())
		{
			return false;
		}
		
		float ClosestDistanceFlattened = 0;
		FQueryLadderData TopScoredLadder;

		for (int i = 0; i < Data.QueryTopEnterLadders.Num(); i++)
		{
			FVector PlayerToLadderFlattenedDelta = (Data.QueryTopEnterLadders[i].GetRungWorldLocation(Data.QueryTopEnterLadders[i].GetTopRung()) - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp);
			FVector PlayerToLadderNormalized = PlayerToLadderFlattenedDelta.GetSafeNormal();

			float Angle = MoveComp.MovementInput.GetSafeNormal().AngularDistanceForNormals(PlayerToLadderNormalized);

			if(Angle > Math::DegreesToRadians(Settings.EnterFromTopInputCutoff))
				continue;
			
			if(TopScoredLadder.Ladder == nullptr && ClosestDistanceFlattened == 0)
			{
				TopScoredLadder.Ladder = Data.QueryTopEnterLadders[i];
				ClosestDistanceFlattened = PlayerToLadderFlattenedDelta.Size();
			}
			else
			{
				if(PlayerToLadderFlattenedDelta.Size() < ClosestDistanceFlattened)
				{
					ClosestDistanceFlattened = PlayerToLadderFlattenedDelta.Size();
					TopScoredLadder.Ladder = Data.QueryTopEnterLadders[i];
				}
			}
		}

		if(TopScoredLadder.Ladder == nullptr)
			return false;

		Data.EnterFromTopLadder = TopScoredLadder.Ladder;
		return true;
	}

	FRotator CalculatePlayerCapsuleRotation(ALadder Ladder)
	{
		FRotator Rotation = FRotator::MakeFromXZ(Ladder.ActorForwardVector, Ladder.ActorUpVector);
		return Rotation;
	}

	void ForcePlayerLadderEntry(ALadder Ladder)
	{
		if (Data.ActiveLadder != nullptr)	
		{
			return;
		}

		FQueryLadderData QueryLadderData;
		QueryLadderData.Ladder = Ladder;
		QueryLadderData.bForceEntry = true;

		for (int i = 0; i < Data.QueryLadderData.Num(); i++)
		{
			if(Data.QueryLadderData[i].Ladder == Ladder)
			{
				Data.QueryLadderData.RemoveAtSwap(i);
				break;
			}
		}

		Data.QueryLadderData.AddUnique(QueryLadderData);
	}
}

struct FPlayerLadderData
{
	//Ladder reference for entering from top
	ALadder EnterFromTopLadder = nullptr;
	//If we overlapped any top ladder zones that were enabled
	TArray<ALadder>QueryTopEnterLadders;
	//Currently overlapped ladders
	TArray<FQueryLadderData>QueryLadderData;
	//Current Ladder Enter Target
	FQueryLadderData TargetLadderData;
	//Current Ladder Top Enter Target
	ALadder TargetTopLadder;
	//Current Ladder In Use
	ALadder ActiveLadder;

	FLadderRung QueryClosestRung;

	bool bHanging = false;
	bool bMoving = false;

	uint EnterFromTopTriggeredFrame = 0;

	void ResetData()
	{
		EnterFromTopLadder = nullptr;
		bHanging = false;
		bMoving = false;
		EnterFromTopTriggeredFrame = 0;
	}
}

struct FQueryLadderData
{
	ALadder Ladder;
	bool bForceEntry = false;
}

struct FPlayerLadderAnimData
{
	UPROPERTY()
	bool bFacingLadderForward;
	UPROPERTY()
	bool bEnterRotateClockwise;
	UPROPERTY()
	bool bEnterRotateCounterClockwise;
	UPROPERTY()
	bool bValidGroundExitFound;
	UPROPERTY()
	bool bTransferUpInitiated = false;

	UPROPERTY()
	EPlayerLadderState State = EPlayerLadderState::Inactive;

	void ResetData()
	{
		bTransferUpInitiated = false;
		bFacingLadderForward = false;
		bEnterRotateClockwise = false;
		bEnterRotateCounterClockwise = false;
		bValidGroundExitFound = false;
		State = EPlayerLadderState::Inactive;
	}
}

enum EPlayerLadderState
{
	Inactive,
	MH,
	ClimbUp,
	ClimbDown,
	ExitOnBottom,
	ExitOnTop,
	EnterFromGround,
	EnterFromAir,
	EnterFromTop,
	LetGo,
	JumpOut,
	AdjustOnStop,
	Dash,
	TransferUp,
	TransferDown
}

