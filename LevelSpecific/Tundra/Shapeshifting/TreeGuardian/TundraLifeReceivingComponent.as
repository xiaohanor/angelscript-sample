struct FTundraLifeReceivingEffectParams
{
	UPROPERTY()
	ETundraPlayerTreeGuardianLifeGivingType LifeGivingType;
}

UCLASS(Abstract)
class UTundraLifeReceivingEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LifeReceivingComp = UTundraLifeReceivingComponent::Get(Owner);
	}

	UPROPERTY()
	UTundraLifeReceivingComponent LifeReceivingComp;

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartLifeGiving(FTundraLifeReceivingEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopLifeGiving(FTundraLifeReceivingEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingHorizontalInput() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMovingHorizontalInput() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingVerticalInput() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMovingVerticalInput() {}
}

event void FLifeReceivingEventNoParams();
event void FLifeReceivingEventOnInteractStartEnd(bool bForced);

enum ETundraLifeReceivingStickAlphaMode
{
	/* The original method of handling horizontal/vertical alpha with the stick, the target is always either 1 or -1. Interp speed is multiplied by input size */
	Original,
	/* A new, different method of handling horizontal/vertical alpha with the stick, the target is current stick input, basically the same as raw input but interped */
	FollowRawInput
}

enum ETundraLifeReceivingRangeMode
{
	Remap,
	Clamp
}

enum ETundraLifeReceivingForceFeedbackMode
{
	/* Will default at ClampBasedOnAlpha but if GetRawHorizontalInput or GetRawVerticalInput (whichever is relevant for this alpha settings) is ever called it will revert to Unclamped */
	Auto,
	/* Disregarding alpha, if holding in a direction which is enabled and has force feedback enabled the force feedback will be applied. */
	Raw,
	/* This will base the force feedback of how much the alpha is currently changing, if alpha stops changing, force feedback will also stop. */
	BasedOnAlpha
}

struct FTundraLifeReceivingPerlinRoughnessData
{
	UPROPERTY()
	bool bEnabled = true;

	UPROPERTY(Meta = (EditCondition = "bEnabled", EditConditionHides))
	float FrequencyMultiplier = 1.0;

	UPROPERTY(Meta = (EditCondition = "bEnabled", EditConditionHides))
	float Offset = 0.0;

	UPROPERTY(Meta = (EditCondition = "bEnabled", EditConditionHides))
	float MagnitudeMultiplier = 0.05;
}

struct FTundraLifeReceivingAlphaSettings
{
	/* If this alpha direction is enabled, if false it will not update at all */
	UPROPERTY()
	bool bEnabled = true;

	UPROPERTY()
	bool bEnableForceFeedback = true;

	UPROPERTY()
	float ForceFeedbackMultiplier = 1.0;

	UPROPERTY(Meta = (EditCondition = "bEnableForceFeedback", EditConditionHides))
	ETundraLifeReceivingForceFeedbackMode ForceFeedbackMode = ETundraLifeReceivingForceFeedbackMode::Auto;

	UPROPERTY(Meta = (EditCondition = "bEnabled", EditConditionHides))
	ETundraLifeReceivingStickAlphaMode AlphaMode = ETundraLifeReceivingStickAlphaMode::Original;

	/* The alpha will be set to this at BeginPlay */
	UPROPERTY(Meta = (EditCondition = "bEnabled", EditConditionHides))
	float StartingAlpha = 0.0;

	/* If true, will interp input using a constant interp and then treat that as input to all the alpha modes */
	UPROPERTY(Meta = (EditCondition = "bEnabled", EditConditionHides))
	bool bDoInitialInputConstantInterp = false;

	/* Will only be used if bUseDoubleInterp is true, this will be the first interp on the stick input and then another interp will interp towards that */
	UPROPERTY(Meta = (EditCondition = "bEnabled && bDoInitialInputConstantInterp", EditConditionHides))
	float InitialInputConstantInterpSpeed = 2.0;

	UPROPERTY(Meta = (EditCondition = "bEnabled", EditConditionHides))
	bool bConstantInterpSpeed = false;

	/* Negative speed means instant snap to target */
	UPROPERTY(Meta = (EditCondition = "bEnabled", EditConditionHides))
	float InterpSpeed = 2.0;

	UPROPERTY(Meta = (EditCondition = "bEnabled", EditConditionHides))
	bool bSeparateResetSpeed = false;

	UPROPERTY(meta = (EditCondition = "bEnabled && bSeparateResetSpeed"))
	float ResetInterpSpeed = 2.0;

	UPROPERTY(Meta = (EditCondition = "bEnabled", EditConditionHides))
	FHazeRange OutputRange = FHazeRange(-1.0, 1.0);

	UPROPERTY(Meta = (EditCondition = "bEnabled", EditConditionHides))
	ETundraLifeReceivingRangeMode RangeMode = ETundraLifeReceivingRangeMode::Remap;

	UPROPERTY(Meta = (EditCondition = "bEnabled", EditConditionHides))
	TArray<FTundraLifeReceivingPerlinRoughnessData> PerlinRoughnessLayers;

	float GetTheoreticalMaxSpeed()
	{
		float Speed = InterpSpeed > ResetInterpSpeed ? InterpSpeed : ResetInterpSpeed;
		float MaxDist = Math::Abs(OutputRange.Max - OutputRange.Min);

		if(!bConstantInterpSpeed)
			return Speed * MaxDist;
		else
			return Speed;
	}
}

class UTundraLifeReceivingComponent : UActorComponent
{
	/* If true the tree guardian cannot exit life give on their own. They have to be forced out */
	UPROPERTY(EditAnywhere)
	bool bBlockCancel = false;

	/* If the horizontal/vertical alpha should be reset to 0 when stopping the interact */
	UPROPERTY(EditAnywhere)
	bool bResetAlphaOnStopInteract = false;

	/* How many seconds it will take until the object has been life given completely */
	UPROPERTY(EditAnywhere)
	float DurationToLife = 2.0;

	/* How many seconds it will take for the object to go from life force 1 to 0. */
	UPROPERTY(EditAnywhere)
	float DurationToDeath = 2.0;

	UPROPERTY(EditAnywhere)
	float BaseLifeForce = 0.1;

	/* The cooldown between interacts */
	UPROPERTY(EditAnywhere)
	float InteractCooldown = 0.3;

	UPROPERTY(EditAnywhere)
	bool bShouldTriggerInteractDuringLifeGiveIfHolding = false;

	UPROPERTY(EditAnywhere)
	float DurationToHoldToTriggerInteract = 0.2;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt TutorialPromptWhenPossibleToLifeGive;
	default TutorialPromptWhenPossibleToLifeGive.Action = ActionNames::PrimaryLevelAbility;
	default TutorialPromptWhenPossibleToLifeGive.Text = NSLOCTEXT("Tundra", "Give Life", "Give Life");

	UPROPERTY(EditAnywhere)
	bool bEnableInteractDuringLifeGive = true;

	UPROPERTY(EditAnywhere)
	FTundraLifeReceivingAlphaSettings HorizontalAlphaSettings;

	UPROPERTY(EditAnywhere)
	FTundraLifeReceivingAlphaSettings VerticalAlphaSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Feedback")
	UForceFeedbackEffect ZoeRumble;

	UPROPERTY(EditAnywhere, BlueprintHidden, Meta = (InlineEditConditionToggle))
	bool bOverrideFeatureTag = false;

	UPROPERTY(EditAnywhere, BlueprintHidden, Meta = (EditCondition = "bOverrideFeatureTag"))
	FName OverrideFeatureTag = NAME_None;

	UPROPERTY(EditInstanceOnly, BlueprintHidden)
	TArray<AActor> EmissiveLifeGivingActors;

	UPROPERTY(VisibleInstanceOnly, BlueprintHidden)
	FName EmissiveParameterName = n"LifeGivingAlpha";

	/* Gets called when life force has reached 0 */
	UPROPERTY()
	FLifeReceivingEventNoParams OnDead;

	/* Gets called when life force has reached 1 */
	UPROPERTY()
	FLifeReceivingEventNoParams OnAlive;

	/* Gets called when a player starts giving life to this actor */
	UPROPERTY()
	FLifeReceivingEventOnInteractStartEnd OnInteractStart;

	/* Gets called when a player stops giving life to this actor */
	UPROPERTY()
	FLifeReceivingEventOnInteractStartEnd OnInteractStop;

	/* Called every time the player presses RT when life giving */
	UPROPERTY()
	FLifeReceivingEventNoParams OnInteractStartDuringLifeGive;

	/* When player lets go of RT after OnInteractDuringLifeGive was called */
	UPROPERTY()
	FLifeReceivingEventNoParams OnInteractStopDuringLifeGive;

	// X: Vertical alpha, Y: Horizontal alpha, Z: Synced target life force
	UHazeCrumbSyncedVectorComponent SyncedAlpha;

	bool bForceEnter = false;
	bool bForceEnterInstant = false;
	bool bForceExit = false;
	bool bForceExitInstant = false;
	bool bForceBlockCancel = false;
	TArray<UMeshComponent> EmissiveLifeGivingMeshes;
	bool bHasEverCalledGetHorizontalRawInput = false;
	bool bHasEverCalledGetVerticalRawInput = false;

	float TimeOfLastInteract = -100.0;
	bool bCurrentlyInteractingDuringLifeGive = false;
	private bool bInternal_CurrentlyLifeGiven = false;

	private FHazeAcceleratedFloat Internal_LifeForce;
	private float Internal_RawHorizontalInput;
	private float Internal_RawVerticalInput;
	private float InterpedHorizontalInput;
	private float InterpedVerticalInput;
	private TArray<FInstigator> HorizontalAlphaBlockers;
	private TArray<FInstigator> VerticalAlphaBlockers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Owner.SetActorControlSide(Game::Zoe);

		SyncedAlpha = UHazeCrumbSyncedVectorComponent::Create(Owner, FName(f"{Name}_SyncedAlpha"));

		if(IsHorizontalAlphaEnabled())
			InternalHorizontalAlpha = HorizontalAlphaSettings.StartingAlpha;

		if(IsVerticalAlphaEnabled())
			InternalVerticalAlpha = VerticalAlphaSettings.StartingAlpha;

		devCheck(Owner.IsA(AHazeActor), "Life Receiving components cannot be placed on non-HazeActors");

		if(EmissiveLifeGivingActors.Num() > 0)
		{
			for(AActor Actor : EmissiveLifeGivingActors)
			{
				if(Actor == nullptr)
					continue;

				Actor.GetComponentsByClass(UMeshComponent, EmissiveLifeGivingMeshes);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float OldLifeForce = LifeForce;

		for(UMeshComponent Current : EmissiveLifeGivingMeshes)
		{
			Current.SetScalarParameterValueOnMaterials(EmissiveParameterName, LifeForce);
		}

		if(IsCurrentlyLifeGiving())
		{
			if(HasControl())
			{
				float CurrentTarget = BaseLifeForce;

				if(IsHorizontalAlphaEnabled())
					CurrentTarget += Math::Abs(Internal_RawHorizontalInput) * (1.0 - BaseLifeForce);

				if(IsVerticalAlphaEnabled())
					CurrentTarget += Math::Abs(Internal_RawVerticalInput) * (1.0 - BaseLifeForce);

				if(bEnableInteractDuringLifeGive && bCurrentlyInteractingDuringLifeGive)
					CurrentTarget += (1.0 - BaseLifeForce);

				CurrentTarget += VO::GetZoeGaiaVoiceVolume() * (1.0 - BaseLifeForce);
				SyncedLifeForceTarget = Math::Saturate(CurrentTarget);
			}
			
			Internal_LifeForce.AccelerateTo(SyncedAlpha.Value.Z, DurationToLife, DeltaTime);
		}
		else
		{
			if(HasControl())
			{
				SyncedLifeForceTarget = 0.0;
			}

			Internal_LifeForce.AccelerateTo(SyncedLifeForceTarget, DurationToDeath, DeltaTime);
		}

		if(LifeForce >= 1.0 && OldLifeForce < 1.0)
			OnAlive.Broadcast();

		if(LifeForce <= 0.0 && OldLifeForce > 0.0)
			OnDead.Broadcast();

		if(HasControl())
		{
			if(IsCurrentlyLifeGiving())
			{
				float HorizontalInput = Internal_RawHorizontalInput;
				float VerticalInput = Internal_RawVerticalInput;

				if(IsHorizontalAlphaEnabled() && HorizontalAlphaSettings.bDoInitialInputConstantInterp)
				{
					InterpedHorizontalInput = Math::FInterpConstantTo(InterpedHorizontalInput, HorizontalInput, DeltaTime, HorizontalAlphaSettings.InitialInputConstantInterpSpeed);
					HorizontalInput = InterpedHorizontalInput;
				}

				if(IsVerticalAlphaEnabled() && VerticalAlphaSettings.bDoInitialInputConstantInterp)
				{
					InterpedVerticalInput = Math::FInterpConstantTo(InterpedVerticalInput, VerticalInput, DeltaTime, VerticalAlphaSettings.InitialInputConstantInterpSpeed);
					VerticalInput = InterpedVerticalInput;
				}

				if(IsHorizontalAlphaEnabled())
					InternalHorizontalAlpha = AccelerateAlpha(InternalHorizontalAlpha, HorizontalInput, HorizontalAlphaSettings, DeltaTime);

				if(IsVerticalAlphaEnabled())
					InternalVerticalAlpha = AccelerateAlpha(InternalVerticalAlpha, VerticalInput, VerticalAlphaSettings, DeltaTime);
			}

			HandleResetAlphas(DeltaTime);
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetVerticalForceFeedbackEnabled(bool bEnabled)
	{
		VerticalAlphaSettings.bEnableForceFeedback = bEnabled;
	}

	UFUNCTION(BlueprintCallable)
	void SetHorizontalForceFeedbackEnabled(bool bEnabled)
	{
		HorizontalAlphaSettings.bEnableForceFeedback = bEnabled;
	}


	// Should be called on both remote and control side
	void StartLifeGiving(ETundraPlayerTreeGuardianLifeGivingType LifeGivingType, bool bForced)
	{
		bInternal_CurrentlyLifeGiven = true;
		OnInteractStart.Broadcast(bForced);

		FTundraLifeReceivingEffectParams Params;
		Params.LifeGivingType = LifeGivingType;
		UTundraLifeReceivingEffectHandler::Trigger_OnStartLifeGiving(Cast<AHazeActor>(Owner), Params);
	}

	// Should be called on both remote and control side
	void StopLifeGiving(ETundraPlayerTreeGuardianLifeGivingType LifeGivingType, bool bForced)
	{
		if(bCurrentlyInteractingDuringLifeGive)
			LocalStopInteract();

		bInternal_CurrentlyLifeGiven = false;
		OnInteractStop.Broadcast(bForced);

		SetRawInput(FVector2D::ZeroVector);

		InterpedHorizontalInput = 0.0;
		InterpedVerticalInput = 0.0;

		FTundraLifeReceivingEffectParams Params;
		Params.LifeGivingType = LifeGivingType;
		UTundraLifeReceivingEffectHandler::Trigger_OnStopLifeGiving(Cast<AHazeActor>(Owner), Params);
	}

	UFUNCTION(BlueprintPure)
	bool IsCurrentlyLifeGiving()
	{
		return bInternal_CurrentlyLifeGiven;
	}

	private void HandleResetAlphas(float DeltaTime)
	{
		if(IsCurrentlyLifeGiving())
			return;
		
		if(!bResetAlphaOnStopInteract)
			return;

		if(IsHorizontalAlphaEnabled() && InternalHorizontalAlpha != HorizontalAlphaSettings.StartingAlpha)
		{
			InternalHorizontalAlpha = InterpAlpha(InternalHorizontalAlpha, HorizontalAlphaSettings.StartingAlpha, DeltaTime, HorizontalAlphaSettings.bSeparateResetSpeed ? HorizontalAlphaSettings.ResetInterpSpeed : HorizontalAlphaSettings.InterpSpeed, HorizontalAlphaSettings.bConstantInterpSpeed);
		}
		if(IsVerticalAlphaEnabled() && InternalVerticalAlpha != VerticalAlphaSettings.StartingAlpha)
		{
			InternalVerticalAlpha = InterpAlpha(InternalVerticalAlpha, VerticalAlphaSettings.StartingAlpha, DeltaTime, VerticalAlphaSettings.bSeparateResetSpeed ? VerticalAlphaSettings.ResetInterpSpeed : VerticalAlphaSettings.InterpSpeed, VerticalAlphaSettings.bConstantInterpSpeed);
		}
	}

	void SetRawInput(FVector2D RawInput)
	{
		bool bMovingHorizontal = !Math::IsNearlyZero(RawInput.Y);
		bool bPreviousMovingHorizontal = !Math::IsNearlyZero(Internal_RawHorizontalInput);
		bool bMovingVertical = !Math::IsNearlyZero(RawInput.X);
		bool bPreviousMovingVertical = !Math::IsNearlyZero(Internal_RawVerticalInput);
		
		Internal_RawHorizontalInput = RawInput.Y;
		Internal_RawVerticalInput = RawInput.X;

		if(bMovingHorizontal != bPreviousMovingHorizontal)
		{
			if(bMovingHorizontal)
				UTundraLifeReceivingEffectHandler::Trigger_OnStartMovingHorizontalInput(Cast<AHazeActor>(Owner));
			else
				UTundraLifeReceivingEffectHandler::Trigger_OnStopMovingHorizontalInput(Cast<AHazeActor>(Owner));
		}

		if(bMovingVertical != bPreviousMovingVertical)
		{
			if(bMovingVertical)
				UTundraLifeReceivingEffectHandler::Trigger_OnStartMovingVerticalInput(Cast<AHazeActor>(Owner));
			else
				UTundraLifeReceivingEffectHandler::Trigger_OnStopMovingVerticalInput(Cast<AHazeActor>(Owner));
		}
	}

	private float AccelerateAlpha(float CurrentAlpha, float StickInput, FTundraLifeReceivingAlphaSettings AlphaSettings, float DeltaTime)
	{
		switch(AlphaSettings.AlphaMode)
		{
			case ETundraLifeReceivingStickAlphaMode::Original:
				return AccelerateOriginalAlpha(CurrentAlpha, StickInput, AlphaSettings, DeltaTime);

			case ETundraLifeReceivingStickAlphaMode::FollowRawInput:
				return AccelerateFollowRawAlpha(CurrentAlpha, StickInput, AlphaSettings, DeltaTime);
			default:
				devError("This alpha mode is not handled!");
		}

		return CurrentAlpha;
	}

	private float AccelerateOriginalAlpha(float Alpha, float StickInput, FTundraLifeReceivingAlphaSettings AlphaSettings, float DeltaTime)
	{
		float Target = Math::Sign(StickInput);
		Target = ApplyOutputRange(Target, AlphaSettings.RangeMode, AlphaSettings.OutputRange);

		float InterpSpeed = AlphaSettings.InterpSpeed * Math::Abs(StickInput);

		if(AlphaSettings.bSeparateResetSpeed && Target == 0.0)
			InterpSpeed = AlphaSettings.ResetInterpSpeed * Math::Abs(StickInput);

		if(InterpSpeed == 0.0)
			return Alpha;

		return InterpAlpha(Alpha, Target, DeltaTime, InterpSpeed, AlphaSettings.bConstantInterpSpeed);
	}

	private float AccelerateFollowRawAlpha(float Alpha, float StickInput, FTundraLifeReceivingAlphaSettings AlphaSettings, float DeltaTime)
	{
		float Target = StickInput;
		Target = ApplyOutputRange(Target, AlphaSettings.RangeMode, AlphaSettings.OutputRange);

		float InterpSpeed = AlphaSettings.InterpSpeed;

		if(AlphaSettings.bSeparateResetSpeed && Math::Abs(Target) < Math::Abs(Alpha))
			InterpSpeed = AlphaSettings.ResetInterpSpeed;

		return InterpAlpha(Alpha, Target, DeltaTime, InterpSpeed, AlphaSettings.bConstantInterpSpeed);
	}

	private float ApplyOutputRange(float Target, ETundraLifeReceivingRangeMode RangeMode, FHazeRange OutputRange, FVector2D InputRange = FVector2D(-1.0, 1.0))
	{
		float NewTarget = Target;

		switch(RangeMode)
		{
			case ETundraLifeReceivingRangeMode::Remap:
				NewTarget = Math::GetMappedRangeValueClamped(InputRange, OutputRange.ConvertToVector2D(), NewTarget);
				break;

			case ETundraLifeReceivingRangeMode::Clamp:
				NewTarget = Math::Clamp(NewTarget, OutputRange.Min, OutputRange.Max);
				break;

			default:
				devError("This range mode is not handled!");
		}
		
		return NewTarget;
	}

	private float InterpAlpha(float Alpha, float Target, float DeltaTime, float InterpSpeed, bool bConstantSpeed)
	{
		if(InterpSpeed <= 0.0)
			return Target;

		if(bConstantSpeed)
			return Math::FInterpConstantTo(Alpha, Target, DeltaTime, InterpSpeed);

		return Math::FInterpTo(Alpha, Target, DeltaTime, InterpSpeed);
	}

	float GetPerlinAlphaFromAlpha(float Alpha, const FTundraLifeReceivingAlphaSettings& AlphaSettings) const
	{
		float PerlinOffset = 0.0;
		for(int i = 0; i < AlphaSettings.PerlinRoughnessLayers.Num(); i++)
		{
			const FTundraLifeReceivingPerlinRoughnessData& Data = AlphaSettings.PerlinRoughnessLayers[i];
			if(!Data.bEnabled)
				continue;

			float PerlinValue = Math::PerlinNoise1D(Alpha * Data.FrequencyMultiplier + Data.Offset);
			PerlinOffset += PerlinValue * Data.MagnitudeMultiplier;
		}

		return Alpha + PerlinOffset;
	}

	// Only call on control side, will crumb to remote side internally
	void TryStartInteract()
	{
		if(!bEnableInteractDuringLifeGive)
			return;

		if(bCurrentlyInteractingDuringLifeGive)
			return;

		float Time = Time::GetGameTimeSeconds();
		if(InteractCooldown > KINDA_SMALL_NUMBER && Time - TimeOfLastInteract < InteractCooldown)
			return;

		TimeOfLastInteract = Time;
		CrumbStartInteract();
	}

	// Only call on control side, will crumb to remote side internally
	void TryStopInteract()
	{
		if(!bEnableInteractDuringLifeGive)
			return;

		if(!bCurrentlyInteractingDuringLifeGive)
			return;

		CrumbStopInteract();
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	private void CrumbStartInteract()
	{
		Game::Zoe.PlayForceFeedback(ZoeRumble, false, true, this);
		OnInteractStartDuringLifeGive.Broadcast();
		bCurrentlyInteractingDuringLifeGive = true;
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	private void CrumbStopInteract()
	{
		Game::Zoe.PlayForceFeedback(ZoeRumble, false, true, this);
		LocalStopInteract();
	}

	private void LocalStopInteract()
	{
		OnInteractStopDuringLifeGive.Broadcast();
		bCurrentlyInteractingDuringLifeGive = false;
	}

	UFUNCTION()
	void ForceEnterLifeGivingInteraction(bool bInstant = false, bool bBlockUserCancel = false)
	{
		bForceEnter = true;
		bForceEnterInstant = bInstant;
		bForceBlockCancel = bBlockUserCancel;
	}

	UFUNCTION()
	void ForceExitLifeGivingInteraction(bool bInstant = false)
	{
		bForceExit = true;
		bForceExitInstant = bInstant;
	}

	UFUNCTION(BlueprintPure)
	bool IsHorizontalAlphaEnabled() const
	{
		if(HorizontalAlphaBlockers.Num() > 0)
			return false;

		return HorizontalAlphaSettings.bEnabled;
	}

	UFUNCTION(BlueprintPure)
	bool IsVerticalAlphaEnabled() const
	{
		if(VerticalAlphaBlockers.Num() > 0)
			return false;

		return VerticalAlphaSettings.bEnabled;
	}

	bool IsHorizontalForceFeedbackEnabled() const
	{
		if(!IsHorizontalAlphaEnabled())
			return false;

		return HorizontalAlphaSettings.bEnableForceFeedback;
	}

	bool IsVerticalForceFeedbackEnabled() const
	{
		if(!IsVerticalAlphaEnabled())
			return false;

		return VerticalAlphaSettings.bEnableForceFeedback;
	}

	ETundraLifeReceivingForceFeedbackMode GetHorizontalForceFeedbackMode() const
	{
		devCheck(IsHorizontalForceFeedbackEnabled(), "Horizontal force feedback isn't enabled, so getting the mode isn't valid!");
		if(HorizontalAlphaSettings.ForceFeedbackMode == ETundraLifeReceivingForceFeedbackMode::Auto)
		{
			if(bHasEverCalledGetHorizontalRawInput)
				return ETundraLifeReceivingForceFeedbackMode::Raw;

			return ETundraLifeReceivingForceFeedbackMode::BasedOnAlpha;
		}

		return HorizontalAlphaSettings.ForceFeedbackMode;
	}

	ETundraLifeReceivingForceFeedbackMode GetVerticalForceFeedbackMode() const
	{
		devCheck(IsVerticalForceFeedbackEnabled(), "Vertical force feedback isn't enabled, so getting the mode isn't valid!");
		if(VerticalAlphaSettings.ForceFeedbackMode == ETundraLifeReceivingForceFeedbackMode::Auto)
		{
			if(bHasEverCalledGetVerticalRawInput)
				return ETundraLifeReceivingForceFeedbackMode::Raw;

			return ETundraLifeReceivingForceFeedbackMode::BasedOnAlpha;
		}

		return VerticalAlphaSettings.ForceFeedbackMode;
	}

	void AddHorizontalAlphaBlocker(FInstigator Instigator)
	{
		HorizontalAlphaBlockers.AddUnique(Instigator);
	}

	void RemoveHorizontalAlphaBlocker(FInstigator Instigator)
	{
		HorizontalAlphaBlockers.RemoveSingleSwap(Instigator);
	}

	void AddVerticalAlphaBlocker(FInstigator Instigator)
	{
		VerticalAlphaBlockers.AddUnique(Instigator);
	}

	void RemoveVerticalAlphaBlocker(FInstigator Instigator)
	{
		VerticalAlphaBlockers.RemoveSingleSwap(Instigator);
	}

	UFUNCTION(BlueprintPure)
	float GetLifeForce() const property
	{
		return Internal_LifeForce.Value;
	}

	private float GetInternalHorizontalAlpha() const property
	{
		if(SyncedAlpha != nullptr)
			return SyncedAlpha.Value.Y;

		return 0.0;
	}

	private float GetInternalVerticalAlpha() const property
	{
		if(SyncedAlpha != nullptr)
			return SyncedAlpha.Value.X;

		return 0.0;
	}

	private void SetInternalHorizontalAlpha(float NewAlpha) property
	{
		SyncedAlpha.Value = FVector(SyncedAlpha.Value.X, NewAlpha, SyncedAlpha.Value.Z);
	}

	private void SetInternalVerticalAlpha(float NewAlpha) property
	{
		SyncedAlpha.Value = FVector(NewAlpha, SyncedAlpha.Value.Y, SyncedAlpha.Value.Z);
	}

	UFUNCTION(BlueprintPure)
	float GetHorizontalAlpha() const property
	{
		return GetPerlinAlphaFromAlpha(InternalHorizontalAlpha, HorizontalAlphaSettings);
	}

	UFUNCTION(BlueprintPure)
	float GetVerticalAlpha() const property
	{
		return GetPerlinAlphaFromAlpha(InternalVerticalAlpha, VerticalAlphaSettings);
	}

	private void SetSyncedLifeForceTarget(float Value) property
	{
		SyncedAlpha.Value = FVector(SyncedAlpha.Value.X, SyncedAlpha.Value.Y, Value);
	}

	private float GetSyncedLifeForceTarget() const property
	{
		return SyncedAlpha.Value.Z;
	}

	/* Try to avoid using this in external systems, if you use it you will have to do the networking yourself to make sure the state of the object gets synced. */
	UFUNCTION(BlueprintPure)
	float GetRawHorizontalInput() property
	{
		bHasEverCalledGetHorizontalRawInput = true;
		return Internal_RawHorizontalInput;
	}

	/* Try to avoid using this in external systems, if you use it you will have to do the networking yourself to make sure the state of the object gets synced. */
	UFUNCTION(BlueprintPure)
	float GetRawVerticalInput() property
	{
		bHasEverCalledGetVerticalRawInput = true;
		return Internal_RawVerticalInput;
	}
}

class UTundraLifeReceivingDetailsCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = UTundraLifeReceivingComponent;

	UTundraLifeReceivingComponent LifeReceivingComp;
	UHazeImmediateDrawer Drawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		LifeReceivingComp = Cast<UTundraLifeReceivingComponent>(GetCustomizedObject());

		if(ShouldDraw())
			Drawer = AddImmediateRow(n"Perlin Noise Preview");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!ShouldDraw())
		{
			if(Drawer != nullptr)
			{
				Drawer.RemoveFromRoot();
				Drawer = nullptr;
				ForceRefresh();
			}
			
			return;
		}
		else
		{
			if(Drawer == nullptr)
			{
				ForceRefresh();
				return;
			}
		}

		if(!Drawer.IsVisible())
			return;

		auto Section = Drawer.Begin();

		if(ShouldDrawHorizontal())
			DrawPerlinCurve(Section, "Horizontal", LifeReceivingComp.HorizontalAlphaSettings);

		if(ShouldDrawVertical())
			DrawPerlinCurve(Section, "Vertical", LifeReceivingComp.VerticalAlphaSettings);

		Drawer.End();
	}

	bool ShouldDraw() const
	{
		if(!ShouldDrawHorizontal() && !ShouldDrawVertical())
			return false;

		return true;
	}

	void DrawPerlinCurve(FHazeImmediateSectionHandle Section, FString Text, const FTundraLifeReceivingAlphaSettings& AlphaSettings)
	{
		Section.Text(Text);
		auto Canvas = Section.PaintCanvas();
		Canvas.Size(FVector2D(Section.WidgetGeometrySize.X, 150.0 + 10.0));

		const float Width = Canvas.WidgetGeometrySize.X;
		const float Height = 150;
		const float XOffset = 0.0;
		const float YOffset = 5.0;
		const FVector2D BottomLeft = FVector2D(XOffset, Height + YOffset);
		const FVector2D TopRight = FVector2D(Width + XOffset, YOffset);
		const float PixelPrecision = 2.0;

		Canvas.Rect(BottomLeft, TopRight);
		Canvas.Line(BottomLeft.X, BottomLeft.Y, TopRight.X, TopRight.Y, FLinearColor(1.0, 1.0, 1.0, 0.2));
		for(float X = 0.0; X < Width; X += PixelPrecision)
		{
			float Alpha = X / Width;
			float FutureAlpha = (X + PixelPrecision) / Width;

			float YAlpha = LifeReceivingComp.GetPerlinAlphaFromAlpha(Alpha, AlphaSettings);
			float YFutureAlpha = LifeReceivingComp.GetPerlinAlphaFromAlpha(FutureAlpha, AlphaSettings);

			Canvas.Line(XOffset + Alpha * Width, YOffset + (1.0 - YAlpha) * Height, XOffset + FutureAlpha * Width, YOffset + (1.0 - YFutureAlpha) * Height);
		}
	}

	bool ShouldDrawHorizontal() const
	{
		return ShouldDrawBasedOnSettings(LifeReceivingComp.HorizontalAlphaSettings);
	}

	bool ShouldDrawVertical() const
	{
		return ShouldDrawBasedOnSettings(LifeReceivingComp.VerticalAlphaSettings);
	}

	bool ShouldDrawBasedOnSettings(const FTundraLifeReceivingAlphaSettings& Settings) const
	{
		if(!Settings.bEnabled)
			return false;

		if(Settings.PerlinRoughnessLayers.Num() == 0)
			return false;

		for(auto Data : Settings.PerlinRoughnessLayers)
		{
			if(Data.bEnabled)
				return true;
		}

		return false;
	}
}