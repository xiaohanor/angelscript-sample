class ASkylineBulwarkDragBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceCompLeft;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceCompRight;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent GravityWhipOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;


	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BoxMesh;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

	UPROPERTY(EditAnywhere)
	ASkylineBulWarkDragBoxHook HookLeft;

	UPROPERTY(EditAnywhere)
	ASkylineBulWarkDragBoxHook HookRight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		

		Trigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
		Trigger.OnPlayerLeave.AddUFunction(this, n"HandleLeave");
		ForceCompLeft.AddDisabler(this);
		ForceCompRight.AddDisabler(this);

		HookLeft.GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleLeftGrabbed");
		HookLeft.GravityWhipTargetComponent.Disable(this);
		HookLeft.GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"HandleLeftReleased");

		HookRight.GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleRightGrabbed");
		HookRight.GravityWhipTargetComponent.Disable(this);
		HookRight.GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"HandleRightReleased");

	}

	UFUNCTION()
	private void HandleRightReleased(UGravityWhipUserComponent UserComponent,
	                                 UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		ForceCompRight.AddDisabler(this);
	}

	UFUNCTION()
	private void HandleRightGrabbed(UGravityWhipUserComponent UserComponent,
	                                UGravityWhipTargetComponent TargetComponent,
	                                TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		ForceCompRight.RemoveDisabler(this);
	}

	UFUNCTION()
	private void HandleLeftReleased(UGravityWhipUserComponent UserComponent,
	                                UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		ForceCompLeft.AddDisabler(this);
	}

	UFUNCTION()
	private void HandleLeftGrabbed(UGravityWhipUserComponent UserComponent,
	                               UGravityWhipTargetComponent TargetComponent,
	                               TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		ForceCompLeft.RemoveDisabler(this);
	}

	UFUNCTION()
	private void HandleLeave(AHazePlayerCharacter Player)
	{
		if(Player==Game::Zoe)
		{
			GravityWhipTargetComponent.Enable(this);
			
			HookLeft.GravityWhipTargetComponent.Disable(this);
			HookRight.GravityWhipTargetComponent.Disable(this);
		}
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		if(Player==Game::Zoe)
		{
			GravityWhipTargetComponent.Disable(this);

			HookLeft.GravityWhipTargetComponent.Enable(this);
			HookRight.GravityWhipTargetComponent.Enable(this);
		}
	}
};