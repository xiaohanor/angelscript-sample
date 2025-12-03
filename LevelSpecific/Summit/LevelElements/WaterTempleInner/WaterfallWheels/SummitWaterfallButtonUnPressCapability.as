class USummitWaterfallButtonUnPressCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitWaterfallButton Button;

	bool bHasFinishedMoving = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Button = Cast<ASummitWaterfallButton>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Button.bIsPressed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Button.bIsPressed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if((Button.ButtonMesh.RelativeLocation - Button.RelativeUnPressedLocation).IsNearlyZero())
			bHasFinishedMoving = true;
		else
			bHasFinishedMoving = false;

		if(Button.WaterfallToActivate != nullptr)
		{
			TArray<AActor> WaterfallChildren;
			Button.WaterfallToActivate.GetAttachedActors(WaterfallChildren);

			for(auto& Child : WaterfallChildren)
			{
				ASpotSound AttachedSpotSound = Cast<ASpotSound>(Child);
				if(AttachedSpotSound != nullptr)
					USummitWaterfallButtonEventHandler::Trigger_OnButtonUnPress(AttachedSpotSound);
			}

			Button.WaterfallToActivate.NiagaraComponent0.Deactivate();
		}

		USummitWaterfallButtonEventHandler::Trigger_OnButtonUnPress(Button);
		Button.OnUnPressed.Broadcast();
		Button.bIsActive = false;

		Button.BP_Unpress();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bHasFinishedMoving)
			return;
		if(ActiveDuration <= Button.MoveLerpDuration)
		{
			float Alpha = ActiveDuration / Button.MoveLerpDuration;
			Button.ButtonMesh.RelativeLocation = Math::Lerp(Button.RelativePressedLocation, Button.RelativeUnPressedLocation, Alpha);
		}
		else
		{
			if(!bHasFinishedMoving)
			{
				Button.ButtonMesh.RelativeLocation = Button.RelativeUnPressedLocation;
				bHasFinishedMoving = true;
			}
		}
	}
};