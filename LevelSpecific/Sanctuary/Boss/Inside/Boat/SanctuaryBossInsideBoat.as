class ASanctuaryBossInsideBoat : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsConeRotateComponent ConeComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = ConeComp)
	USceneComponent BoatRoot;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerCapabilityClasses.Add(USanctuaryBossInsideBoatUserConstrainCapability);

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComponent;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UPROPERTY(DefaultComponent, Attach = BoatRoot)
	USphereComponent SphereCollision;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;
	UPROPERTY(EditAnywhere)
	float BoatRadius = 225.0;

	bool bDoOnce = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstrainHit");
	}

	UFUNCTION()
	private void HandleConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if(Edge ==EFauxPhysicsTranslateConstraintEdge::AxisX_Max && SphereCollision.IsOverlappingActor(Game::Mio) && SphereCollision.IsOverlappingActor(Game::Zoe))
			bDoOnce = false;
		
		if(HitStrength > 100)
			CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(SphereCollision.IsOverlappingActor(Game::Mio) && SphereCollision.IsOverlappingActor(Game::Zoe))
		{
			ForceComp.AddDisabler(this);
		}else if(bDoOnce){
			ForceComp.RemoveDisabler(this);
		}
		
	}
};