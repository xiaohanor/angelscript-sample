event void FIslandOverseerPovComponentArrivedEvent();
event void FIslandOverseerPovComponentPovEvent();

class UIslandOverseerPovComponent : UActorComponent
{
	AAIIslandOverseer Overseer;
	AIslandOverseerPovCameraController PovCamera;

	UPROPERTY()
	FIslandOverseerPovComponentArrivedEvent OnArrived;

	UPROPERTY()
	FIslandOverseerPovComponentPovEvent OnPov;

	UPROPERTY()
	TSubclassOf<UIslandOverseerPovWidget> PovWidgetClass;

	UIslandOverseerPovWidget PovWidget;
	bool bIntroEnded;
	bool bHiddenMesh;

	private int NumberOfHits = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Overseer = Cast<AAIIslandOverseer>(Owner);
		PovCamera = TListedActors<AIslandOverseerPovCameraController>()[0];
		OnArrived.AddUFunction(this, n"Arrived");
		Overseer.OnPhaseChange.AddUFunction(this, n"OnPhaseChange");
		Overseer.HealthComp.OnTakeDamage.AddUFunction(this, n"TakeDamage");
	}

	UFUNCTION()
	private void TakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage,
	                        EDamageType DamageType)
	{
		if(PovWidget == nullptr)
			return;
		if(Overseer.PhaseComp.Phase != EIslandOverseerPhase::PovCombat)
			return;

		PovWidget.Health = Overseer.HealthComp.CurrentHealth;
		if(PovWidget != nullptr)
			PovWidget.OnHit();		

		++NumberOfHits;
		if(NumberOfHits == 3)
			UIslandOverseerPovEventHandler::Trigger_OnVisorCrack(Overseer);

		FOverseerPOVEventData Params;
		
		Params.Player = Cast<AHazePlayerCharacter>(Attacker);
		UIslandOverseerPovEventHandler::Trigger_OnReturnGrenadeHit(Overseer, Params);
	}

	UFUNCTION(BlueprintCallable)
	void OutroStarted()
	{
		if(PovWidget != nullptr)
			SceneView::FullScreenPlayer.RemoveWidget(PovWidget);
		ShowMesh();
	}

	UFUNCTION(BlueprintCallable)
	void IntroEnded()
	{
		bIntroEnded = true;
		HideMesh();
		PovWidget = SceneView::FullScreenPlayer.AddWidget(PovWidgetClass, EHazeWidgetLayer::Gameplay);
		PovWidget.OnStartup();
	}

	UFUNCTION()
	private void OnPhaseChange(EIslandOverseerPhase NewPhase, EIslandOverseerPhase OldPhase)
	{
		if(NewPhase == EIslandOverseerPhase::SideChase)
			PovCamera.bOutro = true;
	}

	UFUNCTION()
	private void Arrived()
	{
		PovCamera.bIntro = true;
	}

	private void HideMesh()
	{
		if(bHiddenMesh)
			return;
		Overseer.AddActorVisualsBlock(this);
		Overseer.EyeLeft.Eye.AddActorVisualsBlock(this);
		Overseer.EyeRight.Eye.AddActorVisualsBlock(this);
		Overseer.RollerManagerComp.LeftRoller.Roller.AddActorVisualsBlock(this);
		Overseer.RollerManagerComp.RightRoller.Roller.AddActorVisualsBlock(this);
		Overseer.AddActorCollisionBlock(this);
		bHiddenMesh = true;
	}

	private void ShowMesh()
	{
		if(!bHiddenMesh)
			return;
		Overseer.RemoveActorVisualsBlock(this);
		Overseer.EyeLeft.Eye.RemoveActorVisualsBlock(this);
		Overseer.EyeRight.Eye.RemoveActorVisualsBlock(this);
		Overseer.RollerManagerComp.LeftRoller.Roller.RemoveActorVisualsBlock(this);
		Overseer.RollerManagerComp.RightRoller.Roller.RemoveActorVisualsBlock(this);
		Overseer.RemoveActorCollisionBlock(this);
		bHiddenMesh = false;
	}
}