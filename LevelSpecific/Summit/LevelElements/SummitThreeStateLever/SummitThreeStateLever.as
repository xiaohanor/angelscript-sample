event void FSummitOnThreeStateLever();

enum ESummitThreeStateLeverState
{
	Left,
	Center,
	Right,
	NotStarted,
	MAX
}

UCLASS(Abstract)
class ASummitThreeStateLever : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	USceneComponent LeverParent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;
	default InteractionComp.InteractionCapability = n"PlayerSummitThreeStateLeverCapability";
	default InteractionComp.MovementSettings = FMoveToParams::SmoothTeleport();
	default InteractionComp.ActionShape.BoxExtents = FVector(75, 75, 100);
	default InteractionComp.ActionShapeTransform = FTransform(FVector(-75, 0, 100));
	default InteractionComp.FocusShape.SphereRadius = 7300.0;
	default InteractionComp.UsableByPlayers = EHazeSelectPlayer::Mio;
	default InteractionComp.WidgetVisualOffset = FVector(0.0, 0.0, 200.0);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(EditAnywhere)
	UHazeLocomotionFeatureBase LeverFeature;

	UPROPERTY(EditAnywhere)
	FVector PlayerOffset = FVector(-80, 0, 15);

	/* Will trigger events when actually changing state (even if it is with a duration) */
	UPROPERTY(EditAnywhere)
	bool bTriggerEventWhenSettingTarget = true;

	UPROPERTY(EditAnywhere)
	bool bStartDisabled = true;

	UPROPERTY(EditAnywhere)
	bool bResetToInitialWhenExiting = true;

	UPROPERTY(EditAnywhere)
	ESummitThreeStateLeverState InitialState = ESummitThreeStateLeverState::Center;

	UPROPERTY()
	FSummitOnThreeStateLever OnLeftState;

	UPROPERTY()
	FSummitOnThreeStateLever OnCenterState;

	UPROPERTY()
	FSummitOnThreeStateLever OnRightState;

	private ESummitThreeStateLeverState InternalCurrentState = ESummitThreeStateLeverState::MAX;
	private ESummitThreeStateLeverState InternalTargetState = ESummitThreeStateLeverState::MAX;
	private FRotator TargetRotation;
	private bool bSlerpLeverRotation = false;
	private float CurrentDuration;
	private float TimeOfStartSlerp = -100.0;
	private float MaxOffsetAngle = 20;
	private FVector InitialWidgetVisualOffset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialWidgetVisualOffset = InteractionComp.WidgetVisualOffset;

		if(!bStartDisabled)
			CrumbChangeState(InitialState);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bSlerpLeverRotation)
		{
			SetActorTickEnabled(false);
			return;
		}

		float CurrentSlerp = (Time::GetGameTimeSeconds() - TimeOfStartSlerp) / CurrentDuration;
		if(CurrentSlerp >= 1.0)
		{
			InternalCurrentState = InternalTargetState;
			bSlerpLeverRotation = false;
			SetActorTickEnabled(false);

			if(bTriggerEventWhenSettingTarget)
				BroadcastOnEnteredState(InternalCurrentState);
			return;
		}

		LeverParent.WorldRotation = FQuat::Slerp(LeverParent.ComponentQuat, TargetRotation.Quaternion(), CurrentSlerp).Rotator();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbChangeState(ESummitThreeStateLeverState NewState, float Duration = -1.0)
	{
		if(NewState == ESummitThreeStateLeverState::MAX)
			return;

		if(NewState == InternalTargetState)
			return;

		TargetRotation = GetRotationOfState(NewState);
		InternalTargetState = NewState;

		FRotator LocalRotation = ActorTransform.InverseTransformRotation(TargetRotation);
		InteractionComp.WidgetVisualOffset = LocalRotation.RotateVector(InitialWidgetVisualOffset);

		if(Duration <= 0.0)
		{
			InternalCurrentState = NewState;
			LeverParent.WorldRotation = TargetRotation;
			BroadcastOnEnteredState(NewState);
		}
		else
		{
			TimeOfStartSlerp = Time::GetGameTimeSeconds();
			CurrentDuration = Duration;
			bSlerpLeverRotation = true;
			SetActorTickEnabled(true);

			if(bTriggerEventWhenSettingTarget)
				BroadcastOnEnteredState(NewState);
		}
	}

	FRotator GetRotationOfState(ESummitThreeStateLeverState State)
	{
		switch(State)
		{
			case ESummitThreeStateLeverState::Left:
				return FRotator::MakeFromXZ(ActorForwardVector, FVector::UpVector.RotateAngleAxis(MaxOffsetAngle, ActorForwardVector));

			case ESummitThreeStateLeverState::Center:
				return FRotator::MakeFromXZ(ActorForwardVector, FVector::UpVector);

			case ESummitThreeStateLeverState::Right:
				return FRotator::MakeFromXZ(ActorForwardVector, FVector::UpVector.RotateAngleAxis(-MaxOffsetAngle, ActorForwardVector));

			default:
		}
		return FRotator();
	}

	void BroadcastOnEnteredState(ESummitThreeStateLeverState State)
	{
		switch(State)
		{
			case ESummitThreeStateLeverState::Left:
				OnLeftState.Broadcast();
				break;

			case ESummitThreeStateLeverState::Center:
				OnCenterState.Broadcast();
				break;

			case ESummitThreeStateLeverState::Right:
				OnRightState.Broadcast();
				break;

			default:
		}

		OnChangeState(State);
	}

	UFUNCTION(BlueprintPure)
	ESummitThreeStateLeverState GetCurrentState() property
	{
		return InternalCurrentState;
	}

	ESummitThreeStateLeverState GetTargetState() property
	{
		return InternalTargetState;
	}

	FVector GetPlayerTargetLocation() const
	{
		FVector PlayerOffsetLeverSpace = ActorTransform.TransformVector(PlayerOffset);
		FVector PlayerLocation = ActorLocation + PlayerOffsetLeverSpace;
		return PlayerLocation;
	}

	float GetBlendAlpha() const
	{
		float BlendAlpha = Math::NormalizeToRange(LeverParent.RelativeRotation.Roll, -MaxOffsetAngle, MaxOffsetAngle) * 2.0 - 1.0;
		TEMPORAL_LOG(this)
			.Value("Blend Alpha", BlendAlpha)
		;
		return BlendAlpha;
	}

	UFUNCTION(BlueprintEvent)
	void OnChangeState(ESummitThreeStateLeverState LeverState) {}
}