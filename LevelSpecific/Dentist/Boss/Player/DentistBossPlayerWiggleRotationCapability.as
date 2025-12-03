class UDentistBossPlayerWiggleRotationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"StickWiggle");
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	UDentistBossSettings Settings;

	UDentistBossPlayerWiggleRotationComponent WiggleRotationComp;
	UStickWiggleComponent WiggleComp;
	UDentistToothPlayerComponent ToothComp;
	UPlayerMovementComponent MoveComp;

	FHazeAcceleratedQuat AccPlayerRelativeRotation;
	FQuat StartRotation;

	const float RotationDuration = 0.3;
	const float WiggleMaxThreshold = 0.85;
	const float AutoWiggleFrequency = 15.0;

	bool bHasCompletedFirstWiggle = false;
	bool bLastWiggledLeft = false;
	bool bWiggleSuccess = false;

	TOptional<float> TimeLastStartedInputting;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = TListedActors<ADentistBoss>().GetSingle();
		Settings = UDentistBossSettings::GetSettings(Dentist);

		WiggleRotationComp = UDentistBossPlayerWiggleRotationComponent::GetOrCreate(Player);
		WiggleComp = UStickWiggleComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(ToothComp == nullptr)
			return false;

		if(Dentist == nullptr)
			return false;

		if(Settings == nullptr)
			return false;

		if(WiggleComp.ActiveWiggles.Num() > 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WiggleComp.ActiveWiggles.IsEmpty())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartRotation = Player.ActorQuat;

		bHasCompletedFirstWiggle = false;
		bLastWiggledLeft = false;
		bWiggleSuccess = false;

		TimeLastStartedInputting.Reset();

		FDentistBossEffectHandlerOnPlayerWiggleStickParams StartedParams;
		StartedParams.Player = Player;
		UDentistBossEffectHandler::Trigger_OnPlayerWiggleStickStarted(Dentist, StartedParams);
	}

	UFUNCTION()
	private void WiggleCompleted()
	{
		bWiggleSuccess = true;
		for (int iWiggle = 0; iWiggle < WiggleComp.ActiveWiggles.Num(); ++iWiggle)
			WiggleComp.ActiveWiggles[iWiggle].OnCompleted.Clear();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(HasControl())
			MoveComp.ClearMovementInput(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(ToothComp == nullptr)
			ToothComp = UDentistToothPlayerComponent::Get(Player);

		if(Dentist == nullptr)
			Dentist = TListedActors<ADentistBoss>().GetSingle();
		
		if(Dentist == nullptr)
			return;

		if(Settings == nullptr)
			Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ToothComp.HasSetMeshRotationThisFrame())
			return;
		
		float WiggleAxis = 0;
		if(IsAutoWiggle())
		{
			float WiggleSin = Math::Sin(ActiveDuration * AutoWiggleFrequency);
			WiggleAxis = WiggleSin;
		}
		else if(IsHoldWiggle())
		{
			float RightInput = 0.0;
			if(HasControl())
			{
				RightInput = GetAttributeFloat(AttributeNames::MoveRight);
				MoveComp.ApplyMovementInput(FVector(0.0, RightInput, 0.0), this);
			}
			else
			{
				RightInput = MoveComp.GetSyncedMovementInputForAnimationOnly().Y;
			}
			if(Math::Abs(RightInput) > 0.1)
			{
				if(!TimeLastStartedInputting.IsSet())
					TimeLastStartedInputting.Set(Time::GameTimeSeconds);
				
				float TimeSinceStartedInputting = Time::GetGameTimeSince(TimeLastStartedInputting.Value);
				float WiggleSin = Math::Sin(TimeSinceStartedInputting * AutoWiggleFrequency);
				WiggleAxis = WiggleSin;
			}
			else
				TimeLastStartedInputting.Reset();
		}
		else if(HasControl())
		{
			FVector2D MovementRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			FVector MovementInput = FVector(MovementRaw.X, MovementRaw.Y, 0);
			MoveComp.ApplyMovementInput(MovementInput, this);
			WiggleAxis = MovementRaw.Y;
		}
		else
		{
			auto MovementInput = MoveComp.GetSyncedMovementInputForAnimationOnly();
			WiggleAxis = MovementInput.Y;
		}

		TEMPORAL_LOG(Player, "Dentist boss wiggle rotation")
			.Value("Input", WiggleAxis)
		;

		if(!bHasCompletedFirstWiggle)
		{
			if(Math::Abs(WiggleAxis) > WiggleMaxThreshold)
			{
				bLastWiggledLeft = Math::Sign(WiggleAxis) < 0;
				bHasCompletedFirstWiggle = true;

				FDentistBossEffectHandlerOnPlayerWiggleStickMaxReachedParams EffectHandlerParams;
				EffectHandlerParams.Player = Player;
				EffectHandlerParams.bWiggledLeft = bLastWiggledLeft;
				UDentistBossEffectHandler::Trigger_OnPlayerWiggleStickMaxReached(Dentist, EffectHandlerParams);
			}
		}
		else if(bLastWiggledLeft
		&& WiggleAxis > WiggleMaxThreshold)
		{
			bLastWiggledLeft = false;
			FDentistBossEffectHandlerOnPlayerWiggleStickMaxReachedParams EffectHandlerParams;
			EffectHandlerParams.Player = Player;
			EffectHandlerParams.bWiggledLeft = bLastWiggledLeft;
			UDentistBossEffectHandler::Trigger_OnPlayerWiggleStickMaxReached(Dentist, EffectHandlerParams);
		}
		else if(!bLastWiggledLeft
		&& WiggleAxis < -WiggleMaxThreshold)
		{
			bLastWiggledLeft = true;
			FDentistBossEffectHandlerOnPlayerWiggleStickMaxReachedParams EffectHandlerParams;
			EffectHandlerParams.Player = Player;
			EffectHandlerParams.bWiggledLeft = bLastWiggledLeft;
			UDentistBossEffectHandler::Trigger_OnPlayerWiggleStickMaxReached(Dentist, EffectHandlerParams);
		}

		FRotator AdditionalRotation = FRotator(0, Settings.ChairAdditionalRotationAtFullWiggle.Yaw * WiggleAxis, Settings.ChairAdditionalRotationAtFullWiggle.Roll * WiggleAxis);
		AccPlayerRelativeRotation.AccelerateTo(AdditionalRotation.Quaternion(), RotationDuration, DeltaTime);

		ToothComp.SetMeshWorldRotation(StartRotation * AccPlayerRelativeRotation.Value, this);
		WiggleRotationComp.RelativeWiggleRotation = AccPlayerRelativeRotation.Value.Rotator();
	}

	bool IsAutoWiggle() const
	{
		if (Player.IsMio() && StickWiggle::CVar_RemoveStickWiggle_Mio.Int == 2)
			return true;
		if(Player.IsZoe() && StickWiggle::CVar_RemoveStickWiggle_Zoe.Int == 2)
			return true;

		return false;
	}

	bool IsHoldWiggle() const
	{
		if (Player.IsMio() && StickWiggle::CVar_RemoveStickWiggle_Mio.Int == 1)
			return true;
		if(Player.IsZoe() && StickWiggle::CVar_RemoveStickWiggle_Zoe.Int == 1)
			return true;

		return false;
	}
};