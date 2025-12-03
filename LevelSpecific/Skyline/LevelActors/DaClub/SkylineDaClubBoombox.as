class ASkylineDaClubBoombox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	USceneComponent WidgetPosition;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	USceneComponent DialRotateRoot;

	UPROPERTY(DefaultComponent, Attach = DialRotateRoot)
	UStaticMeshComponent Dial;

	UPROPERTY(DefaultComponent)
	UInteractionComponent Interact;
	default Interact.InteractionCapabilityClass = USkylineBoomboxInteractionCapability;

	UPROPERTY(DefaultComponent)
 	UHazeCameraComponent InteractCamera;

	AHazePlayerCharacter ActivePlayer;

	UPROPERTY(DefaultComponent)
	UHazeTwoWaySyncedFloatComponent SyncedCurrentSpin;
	UPROPERTY(DefaultComponent)
	UHazeTwoWaySyncedFloatComponent SyncedSpinDirection;

	UPROPERTY(BlueprintReadOnly)
	float AlphaCurrentSpin;

	UFUNCTION(BlueprintEvent)
    void BP_OnInteractionStarted() {};
    UFUNCTION(BlueprintEvent)
    void BP_OnInteractionStopped() {};

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Interact.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");
		Interact.OnInteractionStopped.AddUFunction(this, n"InteractionStopped");
		SyncedCurrentSpin.OverrideSyncRate(EHazeCrumbSyncRate::Low);
	}

	UFUNCTION()
	private void InteractionStarted(UInteractionComponent InteractionComponent,
	                                AHazePlayerCharacter Player)
	{
		FStickSpinSettings Settings;

		Settings.bAllowPlayerCancel = false;
		Settings.WidgetAttachComponent = WidgetPosition;

		ActivePlayer = Player;
		ApplyToPlayer(Player);
		Player.StartStickSpin(Settings, this);

//		Player.GetStickSpinState(this);
		BP_OnInteractionStarted();
		SyncedCurrentSpin.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION()
	private void InteractionStopped(UInteractionComponent InteractionComponent,
	                                AHazePlayerCharacter Player)
	{
		Player.RootOffsetComponent.FreezeLocationAndLerpBackToParent(this, 0.1);
		ClearFromPlayer(Player);
		Player.ClearLocomotionFeatureByInstigator(this);
		BP_OnInteractionStopped();
		ActivePlayer = nullptr;
		Player.StopStickSpin(this);
		SyncedCurrentSpin.OverrideSyncRate(EHazeCrumbSyncRate::Low);
	}

	void ApplyToPlayer(AHazePlayerCharacter Player)
	{
		UHazeCameraComponent Camera = InteractCamera;
		Player.ActivateCamera(Camera, 4.0, this);
	}

	void ClearFromPlayer(AHazePlayerCharacter Player)
	{
		Player.DeactivateCameraByInstigator(this, 4.0);
	}

	void UpdateSpinSyncedValues(float DeltaSeconds)
	{
		if(ActivePlayer == nullptr)
			return;
		if (!ActivePlayer.HasControl())
			return;

		FStickSpinState SpinState; 
		SpinState = ActivePlayer.GetStickSpinState(this);
		float CurrentSpin = SyncedCurrentSpin.Value;
		if (SpinState.Direction == EStickSpinDirection::SpinClockwise)
		{
			SyncedSpinDirection.SetValue(1.0);
			CurrentSpin += 1 * DeltaSeconds;
		}
		else if (SpinState.Direction == EStickSpinDirection::SpinCounterClockwise)
		{
			SyncedSpinDirection.SetValue(-1.0);
			CurrentSpin -= 1 * DeltaSeconds;
		}
		else
			SyncedSpinDirection.SetValue(0.0);

		CurrentSpin = Math::Wrap(CurrentSpin, 0.0, 8.0);
		SyncedCurrentSpin.SetValue(CurrentSpin);
	}

	void UpdateClientThings(float DeltaSeconds)
	{
		if(ActivePlayer == nullptr)
			return;

		ActivePlayer.RequestLocomotion(n"Boombox", this);
		int SpinDirectionFakeEnum = 0;// NotSpinning,
		if (SyncedSpinDirection.Value > 0.5)
		{
			SpinDirectionFakeEnum = 1;// SpinClockwise,
			DialRotateRoot.AddLocalRotation(FRotator(-40, 0,0) * DeltaSeconds);
		}
		if (SyncedSpinDirection.Value < -0.5)
		{
			SpinDirectionFakeEnum = 2;// SpinCounterClockwise,
			DialRotateRoot.AddLocalRotation(FRotator(40, 0.0,0) * DeltaSeconds);
		}
		ActivePlayer.SetAnimIntParam(n"BoomBoxSpinState", SpinDirectionFakeEnum);

		const float CurrentSpin = SyncedCurrentSpin.Value;
		AlphaCurrentSpin = Math::GetMappedRangeValueClamped(FVector2D(0.0, 8.0), FVector2D(0, 1.0), CurrentSpin);

		if (CurrentSpin > 0.0 && CurrentSpin < 1.0)
			USkylineDaClubBoomboxEventHandler::Trigger_Static(this);

 		if (CurrentSpin > 1.0 && CurrentSpin < 2.0)
			USkylineDaClubBoomboxEventHandler::Trigger_ChannelOne(this);

		if (CurrentSpin > 2.0 && CurrentSpin <3.0)
			USkylineDaClubBoomboxEventHandler::Trigger_Static(this);

		if (CurrentSpin > 3.0 && CurrentSpin < 4.0)
		 	USkylineDaClubBoomboxEventHandler::Trigger_ChannelTwo(this);

		if (CurrentSpin > 4.0 && CurrentSpin < 5.0)
		 	USkylineDaClubBoomboxEventHandler::Trigger_Static(this);

 		if (CurrentSpin > 5.0 && CurrentSpin < 6.0)
		 	USkylineDaClubBoomboxEventHandler::Trigger_ChannelThree(this);

		if (CurrentSpin > 6.0 && CurrentSpin < 7.0)
			USkylineDaClubBoomboxEventHandler::Trigger_Static(this);

 		if (CurrentSpin > 7.0 && CurrentSpin < 8.0)
		 	USkylineDaClubBoomboxEventHandler::Trigger_ChannelFour(this);

		// Debug::DrawDebugString(ActorLocation, "Dial " + AlphaCurrentSpin + " Rot: " + DialRotateRoot.RelativeRotation.Pitch);
	}
};

class USkylineBoomboxInteractionCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	ASkylineDaClubBoombox Boombox;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		Boombox = Cast<ASkylineDaClubBoombox>(ActiveInteraction.Owner);
		Boombox.Interact.SetPlayerIsAbleToCancel(Player, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Boombox.Interact.SetPlayerIsAbleToCancel(Player, ActiveDuration > 0.5);
		Boombox.UpdateSpinSyncedValues(DeltaTime);
		Boombox.UpdateClientThings(DeltaTime);
	}
}