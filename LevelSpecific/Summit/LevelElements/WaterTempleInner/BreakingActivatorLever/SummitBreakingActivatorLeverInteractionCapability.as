class USummitWaterTempleInnerBreakingActivatorLeverInteractionCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;

	ASummitWaterTempleInnerBreakingActivatorLever CurrentLever;

	const float EnterDuration = 0.7;

	float TimeLastEnterFinished;

	bool bHasEntered = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		CurrentLever = Cast<ASummitWaterTempleInnerBreakingActivatorLever>(Params.Interaction.Owner);
		Player.AddLocomotionFeature(CurrentLever.LeverFeature, this);
		bHasEntered = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.RemoveLocomotionFeature(CurrentLever.LeverFeature, this);
		CurrentLever.InteractionComp.Disable(CurrentLever);

		CurrentLever.OnLeverBroken.Broadcast();
		USummitWaterTempleInnerBreakingActivatorLeverEventHandler::Trigger_OnLeverBroken(CurrentLever);
		CurrentLever.BreakOffHandle();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.RequestLocomotion(n"ThreeStateLever", this);
		if (ActiveDuration < EnterDuration)
		{
			Player.SetAnimFloatParam(n"ThreeStateLeverBlendSpaceAlpha", BlendAlpha);
			return;
		}

		if (!bHasEntered)
		{
			TimeLastEnterFinished = Time::GameTimeSeconds;
			CurrentLever.OnActivationStarted.Broadcast();

			FSummitWaterTempleInnerActivatorLeverActivateParams Params;
			Params.Player = Player;
			USummitWaterTempleInnerBreakingActivatorLeverEventHandler::Trigger_OnActivationStarted(CurrentLever, Params);
			bHasEntered = true;
		}

		float Alpha = CurrentLever.AlphaCurve.GetFloatValue(Time::GetGameTimeSince(TimeLastEnterFinished));
		float _, MaxTime = 0;
		CurrentLever.AlphaCurve.GetTimeRange(_, MaxTime);

		// Print(f"{Alpha=}", 0.5);
		float LerpedRoll = Math::Lerp(CurrentLever.StartRoll, CurrentLever.TargetRoll, Alpha);
		FRotator NewRotation = FRotator(0.0, 0.0, LerpedRoll);
		CurrentLever.LeverRoot.RelativeRotation = NewRotation;
		if (ActiveDuration > MaxTime)
			LeaveInteraction();

		Player.SetAnimFloatParam(n"ThreeStateLeverBlendSpaceAlpha", BlendAlpha);
	}

	float GetBlendAlpha() const property
	{
		Print(f"{CurrentLever.LeverRoot.RelativeRotation.Roll=}", 1);
		float OutBlendAlpha = Math::NormalizeToRange(CurrentLever.LeverRoot.RelativeRotation.Roll, -20, 20) * 2.0 - 1.0;
		TEMPORAL_LOG(this)
			.Value("Blend Alpha", OutBlendAlpha);
		return OutBlendAlpha;
	}
};