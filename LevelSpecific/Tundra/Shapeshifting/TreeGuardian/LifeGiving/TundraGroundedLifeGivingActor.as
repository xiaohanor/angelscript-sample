struct FTundraGroundedLifeGivingActorAnimData
{
	bool bWithinRange;
	bool bStartInteracting;
	bool bInteracting;
}

UCLASS(Abstract)
class ATundraGroundedLifeGivingActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UTundraGroundedLifeReceivingTargetableComponent Targetable;

	UPROPERTY(DefaultComponent)
	UTundraLifeReceivingComponent LifeReceivingComp;

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
	bool bLerpTreeGuardianToPoint = false;

	UPROPERTY(EditInstanceOnly, BlueprintHidden, Meta = (EditCondition = "bLerpTreeGuardianToPoint", EditConditionHides))
	float TreeGuardianLerpDuration = 0.5;

	UPROPERTY(EditInstanceOnly, BlueprintHidden, Meta = (EditCondition = "bLerpTreeGuardianToPoint", EditConditionHides))
	FVector TreeGuardianLerpLocalOffset;

	UPROPERTY(EditInstanceOnly, BlueprintHidden, Meta = (EditCondition = "bLerpTreeGuardianToPoint", EditConditionHides))
	FVector TreeGuardianLerpMeshOffset;

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

	UPROPERTY(Category = "GroundedTargetable Events")
	FTundraGroundedLifeReceivingTargetableEventNoParams OnGroundedCommitInteract;

	UPROPERTY(Category = "GroundedTargetable Events")
	FTundraGroundedLifeReceivingTargetableEventNoParams OnGroundedStopInteract;

	UPROPERTY(Category = "GroundedTargetable Events")
	FTundraGroundedLifeReceivingTargetableEventNoParams OnGroundedFoundTarget;

	UPROPERTY(Category = "GroundedTargetable Events")
	FTundraGroundedLifeReceivingTargetableEventNoParams OnGroundedLostTarget;

	FTundraGroundedLifeGivingActorAnimData AnimData;
	TArray<UMeshComponent> EmissiveLifeGivingMeshes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LifeReceivingComp.OnDead.AddUFunction(this, n"LifeOnDead");
		LifeReceivingComp.OnAlive.AddUFunction(this, n"LifeOnAlive");
		LifeReceivingComp.OnInteractStart.AddUFunction(this, n"OnLifeInteractStart");
		LifeReceivingComp.OnInteractStop.AddUFunction(this, n"OnLifeInteractStop");
		LifeReceivingComp.OnInteractStartDuringLifeGive.AddUFunction(this, n"LifeInteractStartDuringLifeGive");
		LifeReceivingComp.OnInteractStartDuringLifeGive.AddUFunction(this, n"InteractStopDuringLifeGive");

		Targetable.OnFoundTarget.AddUFunction(this, n"OnFoundTarget");
		Targetable.OnLostTarget.AddUFunction(this, n"OnLostTarget");
		Targetable.OnCommitInteract.AddUFunction(this, n"OnCommitInteract");
		Targetable.OnStopInteract.AddUFunction(this, n"OnStopInteract");

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
			Current.SetScalarParameterValueOnMaterials(EmissiveParameterName, LifeReceivingComp.LifeForce);
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
	private void OnLifeInteractStart(bool bForced)
	{
		OnInteractStart.Broadcast(bForced);
		UTundraGroundedLifeGivingEffectHandler::Trigger_OnLifeGivingStarted(this);

		Game::Zoe.ActivateCamera(CameraToActivate, CameraBlendTime, this, CameraPriority);
		AnimData.bInteracting = true;
	}

	UFUNCTION()
	private void OnLifeInteractStop(bool bForced)
	{
		OnInteractStop.Broadcast(bForced);
		UTundraGroundedLifeGivingEffectHandler::Trigger_OnLifeGivingStopped(this);

		Game::Zoe.DeactivateCamera(CameraToActivate, CameraBlendOutTime);
		AnimData.bInteracting = false;
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
	private void OnFoundTarget()
	{
		OnGroundedFoundTarget.Broadcast();
		UTundraGroundedLifeGivingEffectHandler::Trigger_OnGroundedFoundTarget(this);

		AnimData.bWithinRange = true;
	}

	UFUNCTION()
	private void OnLostTarget()
	{
		OnGroundedLostTarget.Broadcast();
		UTundraGroundedLifeGivingEffectHandler::Trigger_OnGroundedLostTarget(this);

		AnimData.bWithinRange = false;
	}

	UFUNCTION()
	private void OnCommitInteract()
	{
		OnGroundedCommitInteract.Broadcast();
		UTundraGroundedLifeGivingEffectHandler::Trigger_OnEnterInteract(this);

		AnimData.bStartInteracting = true;
	}

	UFUNCTION()
	private void OnStopInteract()
	{
		OnGroundedStopInteract.Broadcast();

		AnimData.bStartInteracting = false;
	}
}