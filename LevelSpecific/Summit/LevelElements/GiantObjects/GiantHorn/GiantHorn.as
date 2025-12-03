event void FOnGiantHornActivated();

asset GiantHornInteractionSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UGiantHornBlowCapability);
	Capabilities.Add(UGiantHornBlowAvailableCapability);
}

class AGiantHorn  : AHazeActor
{
	UPROPERTY()
	FOnGiantHornActivated OnGiantHornActivated;

	UPROPERTY()
	FOnGiantHornActivated OnBothGiantHornsActivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UInteractionComponent InteractComp;
	default InteractComp.MovementSettings = FMoveToParams::SmoothTeleport();
	default InteractComp.bPlayerCanCancelInteraction = true;
	default InteractComp.InteractionCapabilityClass = UGiantHornInteractionCapability;
	default InteractComp.InteractionSheet = GiantHornInteractionSheet;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BlowEffectRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PromptAttach;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FHazePlaySlotAnimationParams MioAnim;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FHazePlaySlotAnimationParams AcidDragonAnim;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FHazePlaySlotAnimationParams ZoeAnim;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FHazePlaySlotAnimationParams TailDragonAnim;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	float StartActiveDelay = 0.7;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	float ActiveDuration = 1.0;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	float CooldownTime = 3.0;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	bool bIsDoubleInteract = true;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UForceFeedbackEffect Rumble;

	UPROPERTY(EditInstanceOnly, Category = "Setup", Meta = (EditCondition = "bIsDoubleInteract", EditConditionHides))
	AGiantHorn SiblingHorn;

	UPROPERTY(EditInstanceOnly, Category = "Setup", Meta = (EditCondition = "bIsDoubleInteract", EditConditionHides))
	bool bHasNetworkAuthority = true;

	UPROPERTY()
	bool bIsActive;

	bool bDoubleInteractCompleted = false;
	bool bBlowAvailable = false;
	bool bIsBlowingIntoHorn = false;

	float TimeLastBlewIntoHorn = -MAX_flt;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bIsDoubleInteract)
		{
			if(SiblingHorn != nullptr)
			{
				SiblingHorn.bIsDoubleInteract = true;
				SiblingHorn.SiblingHorn = this;
				if(bHasNetworkAuthority)
					SiblingHorn.bHasNetworkAuthority = false;
				else
					SiblingHorn.bHasNetworkAuthority = true;
			}
		}
		else
		{
			if(SiblingHorn != nullptr)
			{
				SiblingHorn.bIsDoubleInteract = false;
				SiblingHorn.SiblingHorn = nullptr;
			}
		}

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bDoubleInteractCompleted = false;
		if(InteractComp.UsableByPlayers == EHazeSelectPlayer::Mio)
			SetActorControlSide(Game::Mio);
		else
			SetActorControlSide(Game::Zoe);
	}

	UFUNCTION()
	void SetHornAvailableState(bool bHornIsAvailable)
	{
		if (bHornIsAvailable)
			InteractComp.Enable(this);
		else
			InteractComp.Disable(this);
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	void CrumbCompleteDoubleInteractActivation()
	{
		InteractComp.Disable(this);
		OnBothGiantHornsActivated.Broadcast();
		bDoubleInteractCompleted = true;

		TEMPORAL_LOG(this).Event("Double Interact Was Completed");
	}
}