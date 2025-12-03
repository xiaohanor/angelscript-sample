class UDentistSplitToothAIScaredStateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::SplitTooth::SplitToothTag);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 90;

	ADentistSplitToothAI SplitToothAI;
	UDentistSplitToothComponent SplitToothComp;
	UHazeMovementComponent MoveComp;
	
	ADentistSplitToothAICircleConstraint CircleConstraint;

	FVector CurrentRandomInput;
	float LastUpdateInputTime = 0;
	float InputDuration = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitToothAI = Cast<ADentistSplitToothAI>(Owner);
		SplitToothComp = SplitToothAI.SplitToothComp;
		MoveComp = SplitToothAI.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SplitToothAI.State == EDentistSplitToothAIState::Scared)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > 1.0)
		{
			const bool bIsClose = SplitToothAI.ActorLocation.Distance(SplitToothAI.OwningPlayer.ActorLocation) < 500;

			if(!bIsClose)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CircleConstraint = ADentistSplitToothAICircleConstraint::Get();

		SplitToothAI.State = EDentistSplitToothAIState::Scared;
		Owner.ApplySettings(DentistSplitToothAIScaredSettings, this);

		UDentistSplitToothAIEventHandler::Trigger_OnScaredStart(SplitToothAI);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.ClearSettingsByInstigator(this);
		MoveComp.ClearMovementInput(this);

		UDentistSplitToothAIEventHandler::Trigger_OnScaredStop(SplitToothAI);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector JumpDirection = GetJumpDirection();

#if !RELEASE
		TEMPORAL_LOG(Owner).DirectionalArrow("Jump Direction", Owner.ActorLocation, JumpDirection * 500, 20);
#endif

		MoveComp.ApplyMovementInput(JumpDirection, this);
	}

	FVector GetJumpDirection()
	{
		const FVector AILocation = SplitToothAI.ActorLocation;
		const FVector PlayerLocation = SplitToothAI.OwningPlayer.ActorLocation;
		const FVector CenterLocation = CircleConstraint.ActorLocation;

		const float DistanceFromCenter = AILocation.Dist2D(CenterLocation);
		const float DistanceToPlayer = AILocation.Dist2D(PlayerLocation);

		const bool bPlayerClose = DistanceToPlayer < 1000;
		const bool bOnOuterRing = DistanceFromCenter > 1000;
		const bool bPlayerFurtherOut = (PlayerLocation.Dist2D(CenterLocation) > DistanceFromCenter) && (PlayerLocation - CenterLocation).DotProduct((AILocation - CenterLocation)) > 0;

#if !RELEASE
		TEMPORAL_LOG(Owner)
			.Value("bPlayerClose", bPlayerClose)
			.Value("bOnOuterRing", bOnOuterRing)
		;
#endif

		if(bPlayerClose)
		{
			// The player is close

			if(bOnOuterRing)
			{
				if(bPlayerFurtherOut)
				{
					// If the player is further out than we are, move away from it
					return (AILocation - PlayerLocation).GetSafeNormal2D();
				}

				// While in the outer ring, move along the ring away from the player
				const FVector FromCenter = (AILocation - CenterLocation).GetSafeNormal2D();
				const FVector CircleTangent = FVector::UpVector.CrossProduct(FromCenter).GetSafeNormal2D();

				const FVector FromPlayer = (AILocation - PlayerLocation).GetSafeNormal2D();

				FVector Direction = FVector::ZeroVector;

				if(FromPlayer.DotProduct(CircleTangent) > 0)
				{
					// Clockwise
					Direction = CircleTangent;
				}
				else
				{
					// Counter-clockwise
					Direction = -CircleTangent;
				}

				if(DistanceFromCenter > 1500)
				{
					// We are on the edge, just keep jumping along it
					return Direction;
				}
				
				else
				{
					return (Direction + FromPlayer).GetSafeNormal2D();
				}
			}
			else
			{
				// While in the inner ring, move away from the player
				return (AILocation - PlayerLocation).GetSafeNormal2D();
			}
		}
		else
		{
			// The player is far away
			if(bOnOuterRing)
			{
				// Random movement
				if(ShouldGenerateNewRightInput())
					GenerateNewRightInput();

				return CurrentRandomInput;
			}
			else
			{
				// While in the inner ring, move away from the player
				return (AILocation - PlayerLocation).GetSafeNormal2D();
			}
		}
	}

	bool ShouldGenerateNewRightInput() const
	{
		if(Time::GetGameTimeSince(LastUpdateInputTime) < InputDuration)
			return false;

		return true;
	}

	void GenerateNewRightInput()
	{
		CurrentRandomInput = Math::GetRandomPointInCircle_XY();
		LastUpdateInputTime = Time::GameTimeSeconds;
		InputDuration = SplitToothAI.Settings.InputDuration.Rand();
	}
};