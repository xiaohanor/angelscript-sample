class UStickSpinCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"StickSpin");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Input;

	UStickSpinComponent SpinComp;
	UHazeCrumbSyncedVectorComponent SpinSyncComp;

	FActiveStickSpin ActiveSpin;
	UStickSpinWidget Widget;

	bool bWasCancelPressed = false;
	FVector2D PreviousStickInput;

	const float SpinBucketDuration = 0.2;
	float SpinBucketTimer = 0.0;
	float SpinBucketMovement = 0.0;
	float PreviousSpinBucketMovement = 0.0;
	float PreviousSpinBucketDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpinComp = UStickSpinComponent::GetOrCreate(Player);

		SpinSyncComp = UHazeCrumbSyncedVectorComponent::GetOrCreate(Player, n"StickSpinSync");
		SpinSyncComp.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FActiveStickSpin& StartedSpin) const
	{
		if (SpinComp.ActiveSpins.Num() == 0)
			return false;

		StartedSpin = SpinComp.ActiveSpins[0];
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FActiveStickSpin StartedSpin)
	{
		ActiveSpin = StartedSpin;
		bWasCancelPressed = false;
		PreviousStickInput = FVector2D::ZeroVector;

		PreviousSpinBucketDuration = 0.0;
		SpinBucketTimer = 0.0;
		SpinBucketMovement = 0.0;

		FActiveStickSpinState& State = SpinComp.GetState(ActiveSpin.Instigator);

		SpinSyncComp.Value = FVector(State.State.SpinPosition, State.State.SpinVelocity, 0.0);
		SpinSyncComp.SnapRemote();

		// Add the Widget
		if (ActiveSpin.Settings.bShowStickSpinWidget)
		{
			if (ActiveSpin.Settings.WidgetAttachComponent == nullptr && ActiveSpin.Settings.WidgetPositionOffset.IsZero())
				Widget = Player.AddWidgetToHUDSlot(n"Tutorial", SpinComp.StickSpinWidget);
			else
				Widget = Player.AddWidget(SpinComp.StickSpinWidget);

			Widget.SetWidgetShowInFullscreen(true);
			Widget.SpinSettings = ActiveSpin.Settings;
			Widget.SpinState = State.State;
			Widget.Start();

			if (ActiveSpin.Settings.WidgetAttachComponent != nullptr)
			{
				Widget.AttachWidgetToComponent(ActiveSpin.Settings.WidgetAttachComponent);
				Widget.SetWidgetRelativeAttachOffset(ActiveSpin.Settings.WidgetPositionOffset);
			}
			else if (!ActiveSpin.Settings.WidgetPositionOffset.IsZero())
			{
				Widget.SetWidgetWorldPosition(ActiveSpin.Settings.WidgetPositionOffset);
			}
		}

		// Block active gameplay if we want to
		if (ActiveSpin.Settings.bBlockOtherGameplay)
		{
			Player.BlockCapabilitiesExcluding(n"GameplayAction", n"UsableWhileButtonMashing", this);
			Player.BlockCapabilitiesExcluding(n"MovementInput", n"UsableWhileButtonMashing", this);
		}

		// Add cancel prompt if canceling is allowed
		if (ActiveSpin.Settings.bAllowPlayerCancel)
		{
			Player.ShowCancelPrompt(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SpinComp.ActiveSpins.Num() == 0 || SpinComp.ActiveSpins[0].Instigator != ActiveSpin.Instigator)
		{
			// Button mash was stopped externally
			return true;
		}

		if (bWasCancelPressed)
		{
			// Player hit cancel to stop the button mash
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SpinComp.ClearState(ActiveSpin.Instigator);

		if (Widget != nullptr)
		{
			Player.RemoveWidget(Widget);
			Widget = nullptr;
		}

		if (HasControl())
		{
			SpinComp.StopStickSpin(ActiveSpin.Instigator);
		}

		// Unblock active gameplay we've blocked
		if (ActiveSpin.Settings.bBlockOtherGameplay)
		{
			Player.UnblockCapabilities(n"GameplayAction", this);
			Player.UnblockCapabilities(n"MovementInput", this);
		}

		ActiveSpin.OnStopped.ExecuteIfBound();

		if (ActiveSpin.Settings.bAllowPlayerCancel)
			Player.RemoveCancelPromptByInstigator(this);
	}

	bool IsSpinEnabled() const
	{
		if (Player.IsMio())
		{
			if (StickSpin::CVar_RemoveStickSpin_Mio.GetInt() == 0)
				return true;
		}
		else
		{
			if (StickSpin::CVar_RemoveStickSpin_Zoe.GetInt() == 0)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		FActiveStickSpinState& State = SpinComp.GetState(ActiveSpin.Instigator);
		TemporalLog.Value("SpinPosition", State.State.SpinPosition);
		TemporalLog.Value("SpinVelocity", State.State.SpinVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FActiveStickSpinState& State = SpinComp.GetState(ActiveSpin.Instigator);

		if (HasControl())
		{
			const FVector2D RawInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			float PrevPosition = State.State.SpinPosition;

			State.State.Direction = EStickSpinDirection::NotSpinning;

			if (Player.IsUsingGamepad() && IsSpinEnabled())
			{
				if (PreviousStickInput.Size() >= 0.7 && RawInput.Size() >= 0.7)
				{
					float PreviousAngle = Math::Atan2(PreviousStickInput.Y, PreviousStickInput.X);
					float CurrentAngle = Math::Atan2(RawInput.Y, RawInput.X);

					float AngleDifference = Math::FindDeltaAngleRadians(CurrentAngle, PreviousAngle);
					if (Math::Abs(AngleDifference) < 0.5 * PI)
					{
						if (AngleDifference < 0.0 && ActiveSpin.Settings.bAllowSpinCounterClockwise)
						{
							State.State.Direction = EStickSpinDirection::SpinCounterClockwise;
							State.State.SpinPosition += AngleDifference / TWO_PI;
						}
						else if (AngleDifference > 0.0 && ActiveSpin.Settings.bAllowSpinClockwise)
						{
							State.State.Direction = EStickSpinDirection::SpinClockwise;
							State.State.SpinPosition += AngleDifference / TWO_PI;
						}
					}
				}

				PreviousStickInput = RawInput;
			}
			else
			{
				if (RawInput.X < -0.1 && ActiveSpin.Settings.bAllowSpinCounterClockwise)
				{
					State.State.Direction = EStickSpinDirection::SpinCounterClockwise;
					State.State.SpinPosition -= DeltaTime * StickSpin::RemovedSpinSpeed;
				}
				else if (RawInput.X > 0.1 && ActiveSpin.Settings.bAllowSpinClockwise)
				{
					State.State.Direction = EStickSpinDirection::SpinClockwise;
					State.State.SpinPosition += DeltaTime * StickSpin::RemovedSpinSpeed;
				}

				PreviousStickInput = FVector2D::ZeroVector;
			}

			if (ActiveSpin.Settings.bUseMinimumSpinPosition && State.State.SpinPosition < ActiveSpin.Settings.MinimumSpinPosition)
				State.State.SpinPosition = ActiveSpin.Settings.MinimumSpinPosition;
			if (ActiveSpin.Settings.bUseMaximumSpinPosition && State.State.SpinPosition > ActiveSpin.Settings.MaximumSpinPosition)
				State.State.SpinPosition = ActiveSpin.Settings.MaximumSpinPosition;

			float SpinMovement = State.State.SpinPosition - PrevPosition;
			SpinBucketMovement += SpinMovement;
			SpinBucketTimer += DeltaTime;

			if (SpinBucketTimer > SpinBucketDuration)
			{
				PreviousSpinBucketDuration = SpinBucketTimer;
				PreviousSpinBucketMovement = SpinBucketMovement;
				SpinBucketMovement = 0.0;
				SpinBucketTimer = 0.0;
			}

			if (PreviousSpinBucketDuration > 0.0)
			{
				float TotalTime = SpinBucketTimer + PreviousSpinBucketDuration;
				float TotalMovement = PreviousSpinBucketMovement + SpinBucketMovement;
				State.State.SpinVelocity = TotalMovement / TotalTime;
			}
			else
			{
				State.State.SpinVelocity = SpinBucketMovement / Math::Max(SpinBucketTimer, 0.001);
			}

			// Update the synced state for the remote side
			SpinSyncComp.Value = FVector(
				State.State.SpinPosition, State.State.SpinVelocity, 0.0,
			);
		}
		else
		{
			// Synced state into the mash component so it can be accessed
			State.State.SpinPosition = SpinSyncComp.Value.X;
			State.State.SpinVelocity = SpinSyncComp.Value.Y;
		}

		// Update the display widget
		if (Widget != nullptr)
		{
			Widget.SpinState = State.State;

			bool bSimplified = !IsSpinEnabled();
			if (Widget.bIsSimplified != bSimplified)
			{
				Widget.bIsSimplified = bSimplified;
				Widget.BP_UpdateSettings();
			}
		}

		// Cancel the button mash if we're able
		if (HasControl() && ActiveSpin.Settings.bAllowPlayerCancel)
		{
			if (WasActionStarted(ActionNames::Cancel))
			{
				Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
				bWasCancelPressed = true;
			}
		}
	}
};