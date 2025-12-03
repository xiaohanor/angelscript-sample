event void ESummitActivatorLeverEvent();

asset SummitWaterTempleInnerActivatorLeverSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USummitWaterTempleInnerActivatorLeverActivateCapability);
	Blocks.Add(CapabilityTags::Movement);
	Blocks.Add(CapabilityTags::GameplayAction);
}

struct FSummitWaterTempleLeverMoveParams
{
	float StartRoll = 0;
	float TargetRoll = 0;
	bool bLeverGoesToLeft = false;
}
class ASummitWaterTempleInnerActivatorLever : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LeverRoot;

	UPROPERTY(DefaultComponent, Attach = LeverRoot)
	UStaticMeshComponent LeverMesh;

	UPROPERTY(DefaultComponent, Attach = LeverRoot)
	USceneComponent OffsetLocation;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LeverBase;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;
	default InteractionComp.InteractionCapabilityClass = USummitWaterTempleInnerActivatorLeverInteractionCapability;
	default InteractionComp.MovementSettings = FMoveToParams::SmoothTeleport();
	default InteractionComp.ActionShape.BoxExtents = FVector(75, 75, 100);
	default InteractionComp.ActionShapeTransform = FTransform(FVector(-75, 0, 100));
	default InteractionComp.FocusShape.SphereRadius = 7300.0;
	default InteractionComp.UsableByPlayers = EHazeSelectPlayer::Both;
	default InteractionComp.WidgetVisualOffset = FVector(0.0, 0.0, 200.0);
	default InteractionComp.bPlayerCanCancelInteraction = false;
	default InteractionComp.InteractionSheet = SummitWaterTempleInnerActivatorLeverSheet;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitWaterTempleInnerActivatorLeverResetCapability);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UHazeLocomotionFeatureBase LeverFeature;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector PlayerOffset = FVector(-80, 0, 15);

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MoveLeverDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bLeverGoesToLeft = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bDisableAfterUse = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bPingPongLeverDirection = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bDefaultIsLayingDown = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bIsDoubleInteract = false;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bIsDoubleInteract", EditConditionHides))
	ASummitWaterTempleInnerActivatorLever SiblingLever;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bIsDoubleInteract", EditConditionHides))
	bool bHasDoubleInteractAuthority = true;

	UPROPERTY(EditAnywhere, Category = "Settings|Reset")
	bool bResetAfterUse = true;

	UPROPERTY(EditAnywhere, Category = "Settings|Reset", Meta = (EditCondition = "bResetAfterUse", EditConditionHides))
	float ResetDelay = 0.1;

	UPROPERTY(EditAnywhere, Category = "Settings|Reset", Meta = (EditCondition = "bResetAfterUse", EditConditionHides))
	float ResetDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings|Reset", Meta = (EditCondition = "bResetAfterUse && bDisableAfterUse", EditConditionHides))
	bool bReEnableAfterReset = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	TArray<ASummitWaterTempleInnerActivatorLever> LeversToInfluence;

	UPROPERTY(EditAnywhere, Category = "Settings|Player Feedback")
	UForceFeedbackEffect ActivationRumble;

	UPROPERTY(EditAnywhere, Category = "Settings|Player Feedback")
	TSubclassOf<UCameraShakeBase> AfterActivatedCameraShake;

	UPROPERTY()
	ESummitActivatorLeverEvent OnActivationStarted;

	UPROPERTY()
	ESummitActivatorLeverEvent OnActivationFinished;

	UPROPERTY()
	ESummitActivatorLeverEvent OnResetStarted;

	UPROPERTY()
	ESummitActivatorLeverEvent OnResetFinished;

	float LastTimeFinishedInteraction;

	bool bResetRequested = false;
	bool bPlayerIsInteracting = false;
	bool bPlayerIsActivatingLever = false;
	bool bBothPlayersAreInteracting = false;

	const float LeverRotationMax = 20.0;
	const float EnterDuration = 0.7;

	float StartRoll;
	float TargetRoll;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		for (auto OtherLever : LeversToInfluence)
		{
			Debug::DrawDebugArrow(ActorLocation, OtherLever.ActorLocation, 50, FLinearColor::Yellow, 10);
		}
	}
	#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		LeverRoot.RelativeRotation = FRotator(0.0, 0.0, GetStartRotationDegrees());

#if EDITOR
		for(int i = LeversToInfluence.Num() - 1; i >= 0; i--)
		{
			auto Lever = LeversToInfluence[i];
			if(Lever == nullptr)
				continue;
			
			TArray<ASummitWaterTempleInnerActivatorLever> NewLeverList = LeversToInfluence;
			NewLeverList.RemoveSingleSwap(Lever);
			NewLeverList.Add(this);
			Lever.LeversToInfluence = NewLeverList;
			Lever.MarkPackageDirty();
		}

		if(bIsDoubleInteract)
		{
			if(SiblingLever != nullptr)
			{
				SiblingLever.SiblingLever = this;
				SiblingLever.bIsDoubleInteract = true;

				if(SiblingLever.bHasDoubleInteractAuthority)
					bHasDoubleInteractAuthority = false;
				else
					bHasDoubleInteractAuthority = true;
			}
		}
		else
		{
			if(SiblingLever != nullptr)
			{
				SiblingLever.SiblingLever = nullptr;
				SiblingLever.bIsDoubleInteract = false;
				SiblingLever = nullptr;
			}
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector WorldLoc = LeverRoot.WorldLocation + (LeverRoot.UpVector * 170.0);
		FVector LocalPosition = ActorTransform.InverseTransformPosition(WorldLoc);
		FVector Offset = LocalPosition - InteractionComp.RelativeLocation;
		Offset += FVector(70.0, 0.0, 0.0);
		
		InteractionComp.WidgetVisualOffset = Offset;
	}

	void RotateLever(float Alpha, float EasingExp = 1.0)
	{
		float EasedAlpha = Math::EaseInOut(0.0, 1.0, Alpha, EasingExp);
		float LeverLerpedRoll = Math::Lerp(StartRoll, TargetRoll, EasedAlpha);
		FRotator LeverNewRotation = FRotator(0.0, 0.0, LeverLerpedRoll);
		LeverRoot.RelativeRotation = LeverNewRotation;
	}

	float GetStartRotationDegrees() const property
	{
		if(!bDefaultIsLayingDown)
			return 0.0;

		if(bLeverGoesToLeft)
			return LeverRotationMax;
		else
			return -LeverRotationMax;
	}

	float GetTargetRotationDegrees() const property
	{
		if(!bDefaultIsLayingDown)
			return 0.0;

		if(bLeverGoesToLeft)
			return -LeverRotationMax;
		else
			return LeverRotationMax;
	}

	float GetAnimBlendAlpha() const property
	{
		float OutBlendAlpha = Math::NormalizeToRange(LeverRoot.RelativeRotation.Roll, -LeverRotationMax, LeverRotationMax) * 2.0 - 1.0;
		TEMPORAL_LOG(this)
			.Value("Blend Alpha", OutBlendAlpha)
		;
		return OutBlendAlpha;
	}

	bool AnyLinkedNonSiblingLeverIsInteracted() const
	{
		for(auto Lever : LeversToInfluence)
		{
			if(Lever == SiblingLever)
				return false;

			if(Lever.bPlayerIsInteracting)
				return true;
		}

		return false;
	} 
};