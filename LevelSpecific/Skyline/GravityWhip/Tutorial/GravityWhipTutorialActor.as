class AGravityWhipTutorialActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USceneComponent SlingableLocation;

	UPROPERTY(DefaultComponent)
	USceneComponent GrabLocation;

	UPROPERTY(DefaultComponent)
	USceneComponent DragLocation;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	ASkylineCablePanelFront Cablefront;

	UPROPERTY(EditAnywhere)
	ACapabilitySheetVolume SheetVolume;

	UPROPERTY(EditAnywhere)
	ASkylineDraggableDoor Door;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Cablefront!=nullptr)
			Cablefront.GravityWhipResponseComponent.OnThrown.AddUFunction(this, n"HandleOnThrown");

		Door.TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstrainHit");
		
	}

	UFUNCTION()
	private void HandleConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if(Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Max)
			SheetVolume.DisableForPlayer(Game::Zoe, this);
	}

	UFUNCTION()
	private void HandleOnThrown(UGravityWhipUserComponent UserComponent,
	                            UGravityWhipTargetComponent TargetComponent, FHitResult HitResult,
	                            FVector Impulse)
	{
		SlingableLocation.SetRelativeLocation(DragLocation.GetRelativeLocation());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}
};