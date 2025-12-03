class UTundraPlayerOtterFloatingPoleClimbCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTargetablesComponent PlayerTargetablesComponent;
	UTundraPlayerOtterComponent OtterComp;

	UTundraPlayerShapeshiftingComponent ShapeShiftComp;

	UTundraFloatingPoleClimbTargetable CurrentTargetable;
	UPlayerMovementComponent MoveComp;

	const float CameraBlendTime = 5.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		OtterComp = UTundraPlayerOtterComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive() && !IsBlocked())
		{
			PlayerTargetablesComponent.ShowWidgetsForTargetables(UTundraFloatingPoleClimbTargetable);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerOtterFloatingPoleActivatedParams& Params) const
	{
		if(!WasActionStarted(ActionNames::Interaction))
			return false;

		auto Targetable = PlayerTargetablesComponent.GetPrimaryTarget(UTundraFloatingPoleClimbTargetable);

		if(Targetable == nullptr)
			return false;

		auto FloatingPole = Cast<ATundraFloatingPoleClimbActor>(Targetable.Owner);

		if(FloatingPole.Collision.WorldLocation.Distance(Player.ActorLocation) > FloatingPole.CableMaxLengthUntilReleasing)
			return false;

		if(ShapeShiftComp.CurrentShapeType != ETundraShapeshiftShape::Small)
			return false;

		Params.Targetable = Targetable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WasActionStarted(ActionNames::Cancel))
			return true;

		if(OtterComp.CurrentFloatingPole == nullptr)
			return true;

		if(OtterComp.CurrentFloatingPole.Collision.WorldLocation.Distance(Player.ActorLocation) > OtterComp.CurrentFloatingPole.CableMaxLengthUntilReleasing)
			return true;

		if(ShapeShiftComp.CurrentShapeType != ETundraShapeshiftShape::Small)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerOtterFloatingPoleActivatedParams Params)
	{
		CurrentTargetable = Params.Targetable;
		OtterComp.CurrentFloatingPole = Cast<ATundraFloatingPoleClimbActor>(CurrentTargetable.Owner);
		OtterComp.CurrentFloatingPole.bCurrentlyAttached = true;
		OtterComp.CurrentFloatingPole.CablePlayer = Player;

		CurrentTargetable.bDoTrace = true;

		OtterComp.OnFloatingPoleAttach.Broadcast(OtterComp.CurrentFloatingPole);

		UTundraFloatingPoleClimbEffectHandler::Trigger_AttachOtter(OtterComp.CurrentFloatingPole);

		if(OtterComp.CurrentFloatingPole.OptionalCableFloater == nullptr)
		{
			OtterComp.CurrentFloatingPole.Cable.bAttachEnd = true;
			OtterComp.CurrentFloatingPole.Cable.SetAttachEndTo(Player, NAME_None, NAME_None);
		}
		else
		{
			UHazeCharacterSkeletalMeshComponent OtterMesh = Cast<ATundraPlayerOtterActor>(OtterComp.GetShapeActor()).Mesh;
			OtterComp.CurrentFloatingPole.OptionalCableFloater.Attach(OtterMesh);
		}

		Player.ShowCancelPrompt(this);
		Player.ApplySettings(OtterComp.SwimSettingsInFloatingPoleCableInteract, this);
		Player.ApplyCameraSettings(OtterComp.CameraSettingsInFloatingPoleCableInteract, CameraBlendTime, this);

		if(!OtterComp.CurrentFloatingPole.IsPlayerClimbing(Game::Zoe))
			Player.ApplySettings(OtterComp.SwimSettingsInFloatingPoleOverrideWhenZoeNotClimbing, this, EHazeSettingsPriority::Override);

		OtterComp.CurrentFloatingPole.PoleActor.OnStartPoleClimb.AddUFunction(this, n"OnStartPoleClimb");
		OtterComp.CurrentFloatingPole.PoleActor.OnStopPoleClimb.AddUFunction(this, n"OnStopPoleClimb");

		Player.BlockCapabilities(PlayerSwimmingTags::SwimmingDash, this);
		Player.BlockCapabilities(PlayerSwimmingTags::SwimmingDive, this);
		Player.BlockCapabilities(PlayerSwimmingTags::SwimmingJump, this);

		UTundraPlayerOtterEffectHandler::Trigger_OnEnterFloatingPoleCableInteract(OtterComp.OtterActor);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		OtterComp.OnFloatingPoleDetach.Broadcast(OtterComp.CurrentFloatingPole);

		OtterComp.CurrentFloatingPole.bCurrentlyAttached = false;
		OtterComp.CurrentFloatingPole.CablePlayer = nullptr;

		UTundraFloatingPoleClimbEffectHandler::Trigger_DetachOtter(OtterComp.CurrentFloatingPole);

		if(OtterComp.CurrentFloatingPole.OptionalCableFloater == nullptr)
		{
			OtterComp.CurrentFloatingPole.Cable.bAttachEnd = false;
		}
		else
		{
			OtterComp.CurrentFloatingPole.OptionalCableFloater.Detach();
		}

		OtterComp.CurrentFloatingPole.PoleActor.OnStartPoleClimb.Unbind(this, n"OnStartPoleClimb");
		OtterComp.CurrentFloatingPole.PoleActor.OnStopPoleClimb.Unbind(this, n"OnStopPoleClimb");

		OtterComp.CurrentFloatingPole = nullptr;
		Player.RemoveCancelPromptByInstigator(this);
		Player.ClearSettingsByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);

		Player.UnblockCapabilities(PlayerSwimmingTags::SwimmingDash, this);
		Player.UnblockCapabilities(PlayerSwimmingTags::SwimmingDive, this);
		Player.UnblockCapabilities(PlayerSwimmingTags::SwimmingJump, this);

		UTundraPlayerOtterEffectHandler::Trigger_OnExitFloatingPoleCableInteract(OtterComp.OtterActor);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float AdditionalCableLength = 100.0;
		const float DistanceUntilMaxPullback = 500.0;
		const float MaxPullback = 10.0;

		float DistanceToStartFightingBack = OtterComp.CurrentFloatingPole.Cable.CableLength + AdditionalCableLength;

		FVector PlayerToPole = (OtterComp.CurrentFloatingPole.Collision.WorldLocation - Player.ActorLocation);
		float CurrentDistance = PlayerToPole.Size();

		float CurrentPullback = Math::GetMappedRangeValueClamped(FVector2D(DistanceToStartFightingBack, DistanceToStartFightingBack + DistanceUntilMaxPullback), FVector2D(0.0, MaxPullback), CurrentDistance);
		
		MoveComp.AddPendingImpulse(PlayerToPole.GetSafeNormal() * CurrentPullback);

		const float ForceFeedbackPulsatingSpeedMultiplier = 0.5;
		const float HighestForceFeedbackValue = 0.1;
		const float LowestPulsatingMultiplier = 1.0;
		const float HighestPulsatingMultiplier = 1.2;

		float CurrentForceFeedback = Math::GetMappedRangeValueClamped(FVector2D(DistanceToStartFightingBack, DistanceUntilMaxPullback + DistanceUntilMaxPullback), FVector2D(0.0, HighestForceFeedbackValue), CurrentDistance);
		float PulsatingAlpha = (Math::Sin(Time::GameTimeSeconds * ForceFeedbackPulsatingSpeedMultiplier) + 1) * 0.5;
		CurrentForceFeedback *= Math::Lerp(LowestPulsatingMultiplier, HighestPulsatingMultiplier, PulsatingAlpha);
		FHazeFrameForceFeedback ForceFeedback;
		ForceFeedback.RightMotor = CurrentForceFeedback;
		Player.SetFrameForceFeedback(ForceFeedback);
	}

	UFUNCTION()
	private void OnStartPoleClimb(AHazePlayerCharacter In_Player, APoleClimbActor PoleClimbActor)
	{
		if(!In_Player.IsZoe())
			return;

		Player.ClearSettingsWithAsset(OtterComp.SwimSettingsInFloatingPoleOverrideWhenZoeNotClimbing, this);
	}

	UFUNCTION()
	private void OnStopPoleClimb(AHazePlayerCharacter In_Player, APoleClimbActor PoleClimbActor)
	{
		if(!In_Player.IsZoe())
			return;

		Player.ApplySettings(OtterComp.SwimSettingsInFloatingPoleOverrideWhenZoeNotClimbing, this, EHazeSettingsPriority::Override);
	}
}

struct FTundraPlayerOtterFloatingPoleActivatedParams
{
	UTundraFloatingPoleClimbTargetable Targetable;
}