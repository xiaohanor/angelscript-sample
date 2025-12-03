event void FVillagePushableBoxEvent();

UCLASS(Abstract)
class AVillagePushableBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BoxRoot;

	UPROPERTY(DefaultComponent, Attach = BoxRoot)
	USceneComponent InteractionRoot;

	UPROPERTY(DefaultComponent, Attach = InteractionRoot)
	UInteractionComponent LeftInteractionComp;

	UPROPERTY(DefaultComponent, Attach = LeftInteractionComp)
	USceneComponent LeftTutorialAttachComp;

	UPROPERTY(DefaultComponent, Attach = InteractionRoot)
	UInteractionComponent RightInteractionComp;

	UPROPERTY(DefaultComponent, Attach = RightInteractionComp)
	USceneComponent RightTutorialAttachComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;
	default CapabilityRequestComp.PlayerCapabilities.Add(n"VillagePushableBoxPlayerCapability");

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedLocComp; 

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 9000.0;

	UPROPERTY()
	FVillagePushableBoxEvent OnFullyPushed;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence EnterAnim;

	UPROPERTY(EditDefaultsOnly)
	TPerPlayer<UAnimSequence> ExitAnim;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureVillagePushBox MioFeature;
	
	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureVillagePushBox ZoeFeature;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	bool bMioPushing = false;
	bool bZoePushing = false;

	bool bFullyPushed = false;

	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LeftInteractionComp.OnInteractionStarted.AddUFunction(this, n"LeftInteractionStarted");
		RightInteractionComp.OnInteractionStarted.AddUFunction(this, n"RightInteractionStarted");

		LeftInteractionComp.OnInteractionStopped.AddUFunction(this, n"LeftInteractionStopped");
		RightInteractionComp.OnInteractionStopped.AddUFunction(this, n"RightInteractionStopped");

		StartLocation = ActorLocation;
		SyncedLocComp.SetValue(StartLocation);
	}

	UFUNCTION()
	private void LeftInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		UVillagePushableBoxPlayerComponent PlayerComp = UVillagePushableBoxPlayerComponent::GetOrCreate(Player);
		PlayerComp.BoxActor = this;

		UVillagePushableBoxEffectEventHandler::Trigger_PlayerEntered(this, GetEffectEventParams(Player));
	}

	UFUNCTION()
	private void RightInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		UVillagePushableBoxPlayerComponent PlayerComp = UVillagePushableBoxPlayerComponent::GetOrCreate(Player);
		PlayerComp.BoxActor = this;

		UVillagePushableBoxEffectEventHandler::Trigger_PlayerEntered(this, GetEffectEventParams(Player));
	}

	UFUNCTION()
	private void LeftInteractionStopped(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		UVillagePushableBoxPlayerComponent PlayerComp = UVillagePushableBoxPlayerComponent::GetOrCreate(Player);
		PlayerComp.BoxActor = nullptr;

		UVillagePushableBoxEffectEventHandler::Trigger_PlayerLeft(this, GetEffectEventParams(Player));
	}

	UFUNCTION()
	private void RightInteractionStopped(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		UVillagePushableBoxPlayerComponent PlayerComp = UVillagePushableBoxPlayerComponent::GetOrCreate(Player);
		PlayerComp.BoxActor = nullptr;

		UVillagePushableBoxEffectEventHandler::Trigger_PlayerLeft(this, GetEffectEventParams(Player));
	}

	FVillagePushableBoxEffectEventParams GetEffectEventParams(AHazePlayerCharacter Player)
	{
		FVillagePushableBoxEffectEventParams Params;
		Params.Player = Player;
		return Params;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bFullyPushed)
			return;

		if (HasControl())
		{
			if (ActorLocation.Dist2D(StartLocation) >= 443.0) {
				CrumbFullyPushed();
				return;
			}
			
			AActor ParentActor = GetAttachParentActor();
			if (bMioPushing && bZoePushing)
			{
				ParentActor.AddActorLocalOffset(FVector(100.0 * DeltaTime, 0.0, 0.0));
			}

			SyncedLocComp.SetValue(ParentActor.ActorLocation);
		}
		else
		{
			AActor ParentActor = GetAttachParentActor();
			ParentActor.SetActorLocation(SyncedLocComp.Value);
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbFullyPushed()
	{
		bFullyPushed = true;
		BP_FullyPushed();

		LeftInteractionComp.Disable(this);
		RightInteractionComp.Disable(this);

		LeftInteractionComp.KickAnyPlayerOutOfInteraction();
		RightInteractionComp.KickAnyPlayerOutOfInteraction();

		OnFullyPushed.Broadcast();

		UVillagePushableBoxEffectEventHandler::Trigger_Completed(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_FullyPushed() {}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbSetPlayerPushStatus(AHazePlayerCharacter Player, bool bStatus)
	{
		if (Player.IsMio())
			bMioPushing = bStatus;
		if (Player.IsZoe())
			bZoePushing = bStatus;
	}

	bool IsOtherPlayerPushing(AHazePlayerCharacter Player)
	{
		if (Player.IsZoe() && bMioPushing)
			return true;

		if (Player.IsMio() && bZoePushing)
			return true;

		return false;
	}

	bool IsPlayerPushing(AHazePlayerCharacter Player)
	{
		if (Player.IsMio())
			return bMioPushing;
		if (Player.IsZoe())
			return bZoePushing;

		return false;
	}

	float GetDistanceFromStart()
	{
		return StartLocation.Dist2D(ActorLocation, FVector::UpVector);
	}
}

struct FVillagePushableBoxEffectEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

class UVillagePushableBoxEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void PlayerEntered(FVillagePushableBoxEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void PlayerLeft(FVillagePushableBoxEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void PlayerStartStruggling(FVillagePushableBoxEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void PlayerStopStruggling(FVillagePushableBoxEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void PlayerStartPushing(FVillagePushableBoxEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void PlayerStopPushing(FVillagePushableBoxEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void Completed() {}
}