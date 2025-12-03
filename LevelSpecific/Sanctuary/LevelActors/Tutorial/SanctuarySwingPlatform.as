class ASanctuarySwingPlatform : AHazeActor
{
	
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsSpringConstraint SpringConstraint;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComponent;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent GrappleMesh;

	UPROPERTY(DefaultComponent, Attach = GrappleMesh)
	USwingPointComponent SwingPointComp;

	UPROPERTY(DefaultComponent, Attach=Platform)
	UDarkPortalTargetComponent TargetComp1;
	UPROPERTY(DefaultComponent,Attach=Platform)
	UDarkPortalTargetComponent TargetComp2;
	UPROPERTY(DefaultComponent,Attach=Platform)
	UDarkPortalTargetComponent TargetComp3;
	UPROPERTY(DefaultComponent,Attach=Platform)
	UDarkPortalTargetComponent TargetComp4;
	UPROPERTY(DefaultComponent,Attach=Platform)
	UDarkPortalTargetComponent TargetComp5;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Platform;

	

	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
		SwingPointComp.Disable(this);
		DarkPortalResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		DarkPortalResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
	}

	UFUNCTION()
	private void HandleReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		SwingPointComp.Disable(this);
		SpringConstraint.RemoveDisabler(Portal);
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		SwingPointComp.Enable(this);
		SpringConstraint.AddDisabler(Portal);
	}
};