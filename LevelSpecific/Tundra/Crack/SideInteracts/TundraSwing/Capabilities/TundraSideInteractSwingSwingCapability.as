class UTundraSideInteractSwingSwingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraSideInteractSwingSwingerComponent SwingerComp;
	UHazeCrumbSyncedVectorComponent SyncedSwingForce;
	UPlayerMovementComponent MoveComp;
	UPlayerInteractionsComponent PlayerInteractionsComp;

	const float SwingForce = 110.0;

	FTutorialPrompt TutorialPrompt;
	default TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_UpDown;
	default TutorialPrompt.AlternativeDisplayType = ETutorialAlternativePromptDisplay::Keyboard_UpDown;
	default TutorialPrompt.Text = NSLOCTEXT("TundraSideInteractSwing", "Swing", "Swing");

	bool bHasInput = false;
	bool bTutorialPromptShown = false;
	ATundraSideInteractSwing CachedSwing;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SyncedSwingForce = UHazeCrumbSyncedVectorComponent::Create(Player, n"SideInteractSwing_SyncedSwingForce");
		SwingerComp = UTundraSideInteractSwingSwingerComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		PlayerInteractionsComp = UPlayerInteractionsComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Swing == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Swing == nullptr)
			return true;

		if(WasActionStarted(ActionNames::MovementJump))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CachedSwing = Swing;
		SyncedSwingForce.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		ShowPrompt();
		bHasInput = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);
		PlayerInteractionsComp.KickPlayerOutOfAnyInteraction();

		if(!CachedSwing.PlayersToKill.Contains(Player))
		{
			FVector RelativeImpulse = CachedSwing.PlayerCancelRelativeImpulse;

			FVector BaseImpulse = Player.ActorTransform.TransformVectorNoScale(RelativeImpulse);
			FVector ImpulseFromSwing = CachedSwing.SwingPlank.ForwardVector * CachedSwing.GetSwingTranslationSpeed();
			Player.AddMovementImpulse(BaseImpulse + ImpulseFromSwing * CachedSwing.PlayerJumpOffImpulseMultiplier);
		}
		
		Player.PlayForceFeedback(CachedSwing.CancelForceFeedback, false, true, this);
		SyncedSwingForce.OverrideSyncRate(EHazeCrumbSyncRate::Low);
		RemovePrompt();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			float Input = Player.ActorForwardVector.DotProduct(MoveComp.MovementInput);
			if(!Math::IsNearlyZero(Input, 0.1))
				bHasInput = true;

			if(bTutorialPromptShown && ActiveDuration > 0.5 && bHasInput)
				CrumbRemovePrompt();

			FVector Force = Player.ActorForwardVector * (Input * SwingForce);
			SyncedSwingForce.Value = Force;
		}
		
		float ForceFeedbackIntensity = Math::GetMappedRangeValueClamped(FVector2D(0.5, 1), FVector2D(0, 1), Math::Abs(Swing.FauxRotateComp.Velocity));
		// float ForceFeedbackIntensity = Math::Abs(Swing.FauxRotateComp.Velocity);
		Player.SetFrameForceFeedback(Swing.SwingFrameForceFeedback, ForceFeedbackIntensity);
		PrintToScreen(""+Swing.FauxRotateComp.Velocity);
		Swing.FauxRotateComp.ApplyForce(Swing.ActorLocation, SyncedSwingForce.Value);

		if(Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"SwingInteract", this);
	}

	void ShowPrompt()
	{
		if(bTutorialPromptShown)
			return;

		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, Player.CapsuleComponent, FVector(0.0, 0.0, 60.0), 0.0);
		bTutorialPromptShown = true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbRemovePrompt()
	{
		RemovePrompt();
	}

	void RemovePrompt()
	{
		if(!bTutorialPromptShown)
			return;

		Player.RemoveTutorialPromptByInstigator(this);
		bTutorialPromptShown = false;
	}

	ATundraSideInteractSwing GetSwing() const property
	{
		return SwingerComp.ActiveSwing;
	}
}