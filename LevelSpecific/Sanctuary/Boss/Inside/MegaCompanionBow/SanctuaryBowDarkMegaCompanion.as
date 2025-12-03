event void FMegaCompanionGrabSignature();

class ASanctuaryBowDarkMegaCompanion : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase FishMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PortalRoot;

	UPROPERTY(EditInstanceOnly)
	AActor EnterSplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalTargetComponent DummyTarget;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossZoeStatue StatueRoot;

	UPROPERTY()
	FMegaCompanionGrabSignature OnGrabbed;

	UPROPERTY()
	FMegaCompanionGrabSignature OnReleased;

	FTransform TargetTransform;
	USceneComponent BowGrabRoot;

	UPROPERTY(BlueprintReadOnly)
	bool bStatueCompleted = false;

	bool bPortalSpawned = false;

	UPROPERTY(BlueprintReadOnly)
	ADarkPortalActor SpawnedPortal = nullptr;

	UPROPERTY()
	FText TutorialDarkText;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// SplineComp = UHazeSplineComponent::Get(EnterSplineActor);
		// FVector Location = SplineComp.GetWorldLocationAtSplineFraction(0.0);
		// FRotator Rotation = SplineComp.GetWorldRotationAtSplineFraction(0.0).Rotator();
		// SetActorLocationAndRotation(Location, Rotation);

		TargetTransform = ActorTransform;
		PortalRoot.SetHiddenInGame(true, true);
		// FishMesh.SetHiddenInGame(false, true);
		StatueRoot.OnStatueCompleted.AddUFunction(this, n"HandleStatueCompleted");

		AddActorDisable(this);
	}

	UFUNCTION(BlueprintPure)
	float GetFragmentsAlpha()
	{
		PrintToScreenScaled("StatueRoot.Fragments[0].AcceleratedFloat.Value: " + StatueRoot.Fragments[0].AcceleratedFloat.Value, 3.f);
		return StatueRoot.Fragments[0].AcceleratedFloat.Value;
	}

	UFUNCTION()
	private void HandleStatueCompleted()
	{
		bStatueCompleted = true;

		Game::Zoe.RemoveTutorialPromptByInstigator(this);

		Release();
	}

	UFUNCTION()
	void Activate()
	{
		RemoveActorDisable(this);
		SpawnPortal();
	}

	void Grab()
	{
		if (!bPortalSpawned)
			return;

		auto PortalComp = UDarkPortalUserComponent::Get(Game::Zoe);
		for (auto Arm : PortalComp.Portal.SpawnedArms)
		{
			Arm.Extend();
		}

		PortalComp.Portal.bIsGrabActive = true;

		if (!bStatueCompleted)
		{
			for (auto Fragment : StatueRoot.Fragments)
			{
				PortalComp.Portal.Grab(Fragment.DarkPortalTargetComp);
				Fragment.bGrabbed = true;
				Fragment.GrabbingPortal = PortalComp.Portal;
				Fragment.FloatingSceneComp.bMegaPortalGrabbing = true;
			}
			// PrintToScreenScaled("GrabbingFragments", 0.2, FLinearColor::Yellow);
		}
		else
		{
			OnGrabbed.Broadcast();
			PortalComp.Portal.Grab(DummyTarget);
			// Debug::DrawDebugSphere(DummyTarget.GetWorldLocation(), 200, 32, FLinearColor::Blue);
			// PrintToScreenScaled("GRAB");
		}
		
		UDarkPortalEventHandler::Trigger_GrabActivated(PortalComp.Portal);
		UDarkPortalPlayerEventHandler::Trigger_GrabActivated(PortalComp.Player);
	}

	void Release()
	{
		if (!bPortalSpawned)
			return;

		if (!bStatueCompleted)
			return;
		
		OnReleased.Broadcast();

		for (auto Fragment : StatueRoot.Fragments)
		{
			Fragment.bGrabbed = false;
			Fragment.FloatingSceneComp.bMegaPortalGrabbing = false;
		}
		
		auto PortalComp = UDarkPortalUserComponent::Get(Game::Zoe);
		for (auto Arm : PortalComp.Portal.SpawnedArms)
			Arm.Contract();

		PortalComp.Portal.bIsGrabActive = false;
		PortalComp.Portal.PushAndReleaseAll();
		UDarkPortalEventHandler::Trigger_GrabDeactivated(PortalComp.Portal);
		UDarkPortalPlayerEventHandler::Trigger_GrabDeactivated(PortalComp.Player);
	}

	UFUNCTION()
	private void SpawnPortal()
	{
		auto PortalComp = UDarkPortalUserComponent::Get(Game::Zoe);
		PortalComp.Portal.Fire(FDarkPortalTargetData(DummyTarget, NAME_None, PortalRoot.WorldLocation, PortalRoot.UpVector));

		// float ScaleMulti = 3.0;
		auto PTM = PortalRoot.WorldTransform;
		PTM.SetLocation(PTM.Location + (PTM.Rotation.ForwardVector*0.0));
		PTM.SetScale3D(PTM.Scale3D * 3.0);


		PortalComp.Portal.AttachPortal(PTM, PortalRoot);
		PortalComp.Portal.SetState(EDarkPortalState::Settle);
		PortalComp.Portal.bForcedVisible = true;
		PortalComp.Portal.bIsMegaPortal = true;

		FDarkPortalSettledEventData SettleParams;
		SettleParams.PortalTransform = PortalComp.Portal.ActorTransform;
		UDarkPortalEventHandler::Trigger_Settled(PortalComp.Portal, SettleParams);

		DummyTarget.AttachToComponent(BowGrabRoot, NAME_None, EAttachmentRule::SnapToTarget);

		SetActorTransform(TargetTransform);
		FishMesh.SetHiddenInGame(true, true);
		BP_SpawnPortal();

		for (auto Arm : PortalComp.Portal.SpawnedArms)
		{
			Arm.SetNiagaraVariableFloat("ArmScale", 2.0);
			Arm.MegaCompanionScale = 3.0;
		}

		bPortalSpawned = true;

		FTutorialPrompt PortalTutorial;
		PortalTutorial.Action = ActionNames::SecondaryLevelAbility;
		PortalTutorial.Text = NSLOCTEXT("SanctuaryHydra", "DarkCompanionGrab", "Grab");
		PortalTutorial.DisplayType = ETutorialPromptDisplay::ActionHold;
		Game::Zoe.ShowTutorialPromptWorldSpace(PortalTutorial, this, PortalRoot, FVector(0.0, 0.0, 150.0));

		SpawnedPortal = PortalComp.Portal;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Debug::DrawDebugSphere(DummyTarget.WorldLocation);
		// Grab();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_SpawnPortal(){}

	UFUNCTION(BlueprintEvent)
	private void BP_StartGrab(){}

	UFUNCTION(BlueprintEvent)
	private void BP_StopGrab(){}

	UFUNCTION(BlueprintEvent)
	void BP_GrabUpdate(FVector GrabLocation){}
};