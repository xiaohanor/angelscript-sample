struct FGiantHornBlowActivationParams
{
	AGiantHorn Horn;
}

class UGiantHornBlowCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AGiantHorn Horn;

	UPlayerInteractionsComponent InteractionsComp;
	UPlayerTeenDragonComponent DragonComp;

	float AnimDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		InteractionsComp = UPlayerInteractionsComponent::Get(Player);
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGiantHornBlowActivationParams& Params) const
	{
		if(!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 0.5))
			return false;

		if(InteractionsComp.ActiveInteraction == nullptr)
			return false;
		
		AGiantHorn InteractHorn = Cast<AGiantHorn>(InteractionsComp.ActiveInteraction.Owner);
		if(InteractHorn == nullptr)
			return false;

		if(!InteractHorn.bBlowAvailable)
			return false;
		Params.Horn = InteractHorn;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration >= AnimDuration - 0.05)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGiantHornBlowActivationParams Params)
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Player);

		Horn = Params.Horn;
		Horn.InteractComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");

		AnimDuration = Player.IsMio() ? 
			Horn.AcidDragonAnim.Animation.PlayLength : 
			Horn.TailDragonAnim.Animation.PlayLength;

		if(Player.IsMio())
			DragonComp.PlaySlotAnimationDragonAndPlayer(Horn.MioAnim, Horn.AcidDragonAnim);
		else
			DragonComp.PlaySlotAnimationDragonAndPlayer(Horn.ZoeAnim, Horn.TailDragonAnim);

		Horn.InteractComp.bPlayerCanCancelInteraction = false;
		UGiantHornEffectHandler::Trigger_OnHornStartedBlowing(Horn);

		Horn.bBlowAvailable = false;
		Horn.bIsBlowingIntoHorn = true;
		Horn.TimeLastBlewIntoHorn = Time::GameTimeSeconds;

		Player.PlayCameraShake(Horn.CameraShake, this);
		Player.PlayForceFeedback(Horn.Rumble, false, false, this);
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Deactivate();

		UGiantHornEffectHandler::Trigger_OnHornStoppedBlowing(Horn);
		if(Horn.bIsActive)
			UGiantHornEffectHandler::Trigger_OnHornBlowStop(Horn);

		Horn.InteractComp.bPlayerCanCancelInteraction = true;
		Horn.bIsBlowingIntoHorn = false;
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter InteractingPlayer)
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			if(ActiveDuration > Horn.StartActiveDelay)
			{
				if(!Horn.bIsActive)
					CrumbActivate();
			}
			if(Horn.bHasNetworkAuthority)
			{
				if(Horn.SiblingHorn != nullptr)
				{
					if(Horn.bIsActive
					&& Horn.SiblingHorn.bIsActive)
					{
						if(!Horn.bDoubleInteractCompleted)
						{
							Horn.CrumbCompleteDoubleInteractActivation();
							Horn.SiblingHorn.CrumbCompleteDoubleInteractActivation();
						}
					}
				}
			}
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbActivate()
	{
		Horn.bIsActive = true;
		
		Horn.OnGiantHornActivated.Broadcast();

		TEMPORAL_LOG(Horn).Event("Activated!");

		FOnGiantHornBlowParams EffectParams;
		EffectParams.BlowPoint = Horn.BlowEffectRoot;
		UGiantHornEffectHandler::Trigger_OnHornBlow(Horn, EffectParams);
	}

	void Deactivate()
	{
		Horn.bIsActive = false;

		TEMPORAL_LOG(Horn).Event("Deactivated!");
	}
};