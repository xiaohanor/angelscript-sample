event void FFairyHutFireplaceEvent();

UCLASS(Abstract)
class AFairyHutFireplace : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FireplaceNiagara;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTundraShapeshiftingInteractionComponent InteractComp;
	default InteractComp.bPlayerCanCancelInteraction = false;
	default InteractComp.bIsImmediateTrigger = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent FireplaceCam;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams SlotAnimation;

	UPROPERTY(EditAnywhere)
	AHazeSpotLight Spotlight1;

	UPROPERTY(EditAnywhere)
	AHazeSphere HazeSphere;

	UPROPERTY()
	FFairyHutFireplaceEvent OnFireLit;

	UPROPERTY(EditDefaultsOnly)
	float DelayLightFireplace = 2.05;

	default TickGroup = ETickingGroup::TG_PrePhysics;

	AHazePlayerCharacter InteractingPlayer;
	float TimeInteractionStarted;
	bool bIsFireplaceLit;

	UFUNCTION(BlueprintPure)
	bool IsFireplaceLit() const
	{
		return bIsFireplaceLit;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractStarted");
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GetGameTimeSince(TimeInteractionStarted) > DelayLightFireplace)
		{
			if (!bIsFireplaceLit)
				ToggleFireplace(true);

			if (InteractingPlayer.Mesh.CanRequestLocomotion())
				InteractingPlayer.RequestLocomotion(n"Movement", this);
		}
	}

	UFUNCTION()
	private void OnInteractStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		if (InteractingPlayer != nullptr)
			return;

		InteractingPlayer = Player;
		TimeInteractionStarted = Time::GameTimeSeconds;

		SetActorTickEnabled(true);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		auto ShapeShift = UTundraPlayerShapeshiftingComponent::Get(Player);

		UHazeSkeletalMeshComponentBase Mesh = ShapeShift.GetMeshForShapeType(ETundraShapeshiftShape::Small);
		Mesh.PlaySlotAnimation(
			FHazeAnimationDelegate(),
			FHazeAnimationDelegate(this, n"OnAnimationFinished"),
			SlotAnimation);

		Player.ActivateCamera(FireplaceCam, 2.0, this);
	}

	UFUNCTION()
	void OnAnimationFinished()
	{
		SetActorTickEnabled(false);

		InteractingPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		InteractingPlayer.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		InteractingPlayer.DeactivateCamera(FireplaceCam, 2.0);

		InteractingPlayer = nullptr;
	}

	void ToggleFireplace(bool bOn)
	{
		if (bOn)
		{
			UFairyHutEventHandler::Trigger_FirePlaceOn(this);

			HazeSphere.SetActorHiddenInGame(false);
			Spotlight1.SpotLightComponent.SetVisibility(true);
			FireplaceNiagara.Activate(true);

			bIsFireplaceLit = true;

			InteractComp.Disable(this);

			OnFireLit.Broadcast();
		}
		else
		{
			HazeSphere.SetActorHiddenInGame(true);
			Spotlight1.SpotLightComponent.SetVisibility(false);
			FireplaceNiagara.Deactivate();

			InteractComp.Enable(this);

			bIsFireplaceLit = false;

			UFairyHutEventHandler::Trigger_FirePlaceOff(this);
		}
	}

	void FairyHutSlammed()
	{
		ToggleFireplace(false);
	}
};
