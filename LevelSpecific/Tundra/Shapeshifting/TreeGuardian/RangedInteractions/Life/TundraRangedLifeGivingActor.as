struct FTundraRangedLifeGivingActorAnimData
{
	access LifeGivingActor = private, ATundraRangedLifeGivingActor;

	access:LifeGivingActor bool bLookingAt;
	access:LifeGivingActor uint FrameOfStopInteract;
	bool bInteractingWith;
	bool bShot;
	bool bForcedLookingAt;

	bool IsLookingAt() const
	{
		if (bForcedLookingAt)
			return true;

		bool bWasJustInteracting = Time::FrameNumber - FrameOfStopInteract <= 1;
		bool bResult = bLookingAt || bInteractingWith || bWasJustInteracting;
		return bResult;
	}
}

UCLASS(Abstract)
class ATundraRangedLifeGivingActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UTundraTreeGuardianRangedInteractionTargetableComponent RangedTargetable;
	default RangedTargetable.InteractionType = ETundraTreeGuardianRangedInteractionType::LifeGive;
	default RangedTargetable.AutoAimMaxAngle = 8.0;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeSkeletalMeshComponentBase Flower;

	UPROPERTY(DefaultComponent)
	UTundraLifeReceivingComponent LifeReceivingComponent;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditInstanceOnly, BlueprintHidden)
	AHazeCameraActor CameraToActivate;

	UPROPERTY(EditInstanceOnly, BlueprintHidden, Meta = (EditCondition = "CameraToActivate != nullptr", EditConditionHides))
	float CameraBlendTime = 1.0;

	UPROPERTY(EditInstanceOnly, BlueprintHidden, Meta = (EditCondition = "CameraToActivate != nullptr", EditConditionHides))
	float CameraBlendOutTime = -1.0;

	UPROPERTY(EditInstanceOnly, BlueprintHidden, Meta = (EditCondition = "CameraToActivate != nullptr", EditConditionHides))
	EHazeCameraPriority CameraPriority = EHazeCameraPriority::Default;

	UPROPERTY(EditInstanceOnly, BlueprintHidden, Meta = (InlineEditConditionToggle))
	bool bOverrideFeatureTag = false;

	UPROPERTY(EditInstanceOnly, BlueprintHidden, Meta = (EditCondition = "bOverrideFeatureTag"))
	FName OverrideFeatureTag = NAME_None;

	UPROPERTY(EditInstanceOnly, BlueprintHidden)
	TArray<AActor> EmissiveLifeGivingActors;

	UPROPERTY(VisibleInstanceOnly, BlueprintHidden)
	FName EmissiveParameterName = n"LifeGivingAlpha";

	/* Gets called when life force has reached 0 */
	UPROPERTY(Category = "LifeReceivingComponent Events")
	FLifeReceivingEventNoParams OnDead;

	/* Gets called when life force has reached 1 */
	UPROPERTY(Category = "LifeReceivingComponent Events")
	FLifeReceivingEventNoParams OnAlive;

	/* Gets called when a player starts giving life to this actor */
	UPROPERTY(Category = "LifeReceivingComponent Events")
	FLifeReceivingEventOnInteractStartEnd OnInteractStart;

	/* Gets called when a player stops giving life to this actor */
	UPROPERTY(Category = "LifeReceivingComponent Events")
	FLifeReceivingEventOnInteractStartEnd OnInteractStop;

	/* Called every time the player presses RT when life giving */
	UPROPERTY(Category = "LifeReceivingComponent Events")
	FLifeReceivingEventNoParams OnInteractStartDuringLifeGive;

	/* When player lets go of RT after OnInteractDuringLifeGive was called */
	UPROPERTY(Category = "LifeReceivingComponent Events")
	FLifeReceivingEventNoParams OnInteractStopDuringLifeGive;

	/* Called as soon as player claims this interaction (called as soon as player releases RT) */
	UPROPERTY(Category = "RangedInteractionTargetable Events")
	FTundraTreeGuardianRangedInteractionEvent OnRangedCommitInteract;

	/* Called when player is actively in interaction, this means different things for different interacts but for grapple points this will be called when grapple point is reached for instance. */
	UPROPERTY(Category = "RangedInteractionTargetable Events")
	FTundraTreeGuardianRangedInteractionEvent OnRangedStartInteract;

	/* Called when the player exits the interaction */
	UPROPERTY(Category = "RangedInteractionTargetable Events")
	FTundraTreeGuardianRangedInteractionEvent OnRangedStopInteract;

	UPROPERTY(Category = "RangedInteractionTargetable Events")
	FTundraTreeGuardianRangedInteractionSelfEvent OnRangedStartLookingAt;

	UPROPERTY(Category = "RangedInteractionTargetable Events")
	FTundraTreeGuardianRangedInteractionSelfEvent OnRangedStopLookingAt;

	FTundraRangedLifeGivingActorAnimData AnimData;
	TArray<UMeshComponent> EmissiveLifeGivingMeshes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LifeReceivingComponent.OnDead.AddUFunction(this, n"LifeOnDead");
		LifeReceivingComponent.OnAlive.AddUFunction(this, n"LifeOnAlive");
		LifeReceivingComponent.OnInteractStart.AddUFunction(this, n"LifeInteractStart");
		LifeReceivingComponent.OnInteractStop.AddUFunction(this, n"LifeInteractStop");
		LifeReceivingComponent.OnInteractStartDuringLifeGive.AddUFunction(this, n"LifeInteractStartDuringLifeGive");
		LifeReceivingComponent.OnInteractStartDuringLifeGive.AddUFunction(this, n"InteractStopDuringLifeGive");

		RangedTargetable.OnStartLookingAt.AddUFunction(this, n"RangedStartLookingAt");
		RangedTargetable.OnStopLookingAt.AddUFunction(this, n"RangedStopLookingAt");
		RangedTargetable.OnStartInteract.AddUFunction(this, n"RangedStartInteract");
		RangedTargetable.OnCommitInteract.AddUFunction(this, n"RangedCommitInteract");
		RangedTargetable.OnStopInteract.AddUFunction(this, n"RangedStopInteract");

		if(EmissiveLifeGivingActors.Num() > 0)
		{
			SetActorTickEnabled(true);
			for(AActor Actor : EmissiveLifeGivingActors)
			{
				if(Actor == nullptr)
					continue;

				Actor.GetComponentsByClass(UMeshComponent, EmissiveLifeGivingMeshes);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(UMeshComponent Current : EmissiveLifeGivingMeshes)
		{
			Current.SetScalarParameterValueOnMaterials(EmissiveParameterName, LifeReceivingComponent.LifeForce);
		}
	}

	UFUNCTION()
	private void LifeOnDead()
	{
		OnDead.Broadcast();
	}

	UFUNCTION()
	private void LifeOnAlive()
	{
		OnAlive.Broadcast();
	}

	UFUNCTION()
	private void LifeInteractStart(bool bForced)
	{
		OnInteractStart.Broadcast(bForced);

		Game::Zoe.ActivateCamera(CameraToActivate, CameraBlendTime, this, CameraPriority);
		AnimData.bShot = true;
	}

	UFUNCTION()
	private void LifeInteractStop(bool bForced)
	{
		OnInteractStop.Broadcast(bForced);

		Game::Zoe.DeactivateCamera(CameraToActivate, CameraBlendOutTime);
	}

	UFUNCTION()
	private void LifeInteractStartDuringLifeGive()
	{
		OnInteractStartDuringLifeGive.Broadcast();
	}

	UFUNCTION()
	private void InteractStopDuringLifeGive()
	{
		OnInteractStopDuringLifeGive.Broadcast();
	}

	UFUNCTION()
	private void RangedStartLookingAt(UTundraTreeGuardianRangedInteractionTargetableComponent Targetable)
	{
		OnRangedStartLookingAt.Broadcast(Targetable);
		UTundraRangedLifeGivingActorEffectHandler::Trigger_OnStartLookingAt(this);

		AnimData.bLookingAt = true;
	}

	UFUNCTION()
	private void RangedStopLookingAt(UTundraTreeGuardianRangedInteractionTargetableComponent Targetable)
	{
		OnRangedStopLookingAt.Broadcast(Targetable);
		UTundraRangedLifeGivingActorEffectHandler::Trigger_OnStopLookingAt(this);

		AnimData.bLookingAt = false;
	}

	UFUNCTION()
	private void RangedStartInteract()
	{
		OnRangedStartInteract.Broadcast();
	}

	UFUNCTION()
	private void RangedCommitInteract()
	{
		OnRangedCommitInteract.Broadcast();

		AnimData.bInteractingWith = true;
	}

	UFUNCTION()
	private void RangedStopInteract()
	{
		OnRangedStopInteract.Broadcast();

		AnimData.bInteractingWith = false;
		AnimData.bShot = false;
		AnimData.FrameOfStopInteract = Time::FrameNumber;
	}

	UFUNCTION(BlueprintPure)
	void GetLifeGivingAlpha(float&out Horizontal, float&out Vertical)
	{
		Horizontal = LifeReceivingComponent.GetHorizontalAlpha();
		Vertical = LifeReceivingComponent.GetVerticalAlpha();
	}
}