struct FSkylineBuildingDragBoxConstrainHit
{
	float HitStrength = 0.0;
}

UCLASS(Abstract)
class USkylineBuildingDragBoxEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnConstrainHitLowAlpha(FSkylineBuildingDragBoxConstrainHit Param) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnConstrainHitHighAlpha(FSkylineBuildingDragBoxConstrainHit Param) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFurnitureMove() 
	{
	}

};	
class ASkylineBuildingDragBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent FauxPhysicsTranslateComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UStaticMeshComponent FurnitureMeshComp1;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UStaticMeshComponent FurnitureMeshComp2;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UStaticMeshComponent FurnitureMeshComp3;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent GravityWhipOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UFauxPhysicsForceComponent ReturnForceComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	bool bIsFakeBox = false;

	UPROPERTY(EditAnywhere)
	bool bIsLockedBox = false;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpCallbackComp;

	UPROPERTY(EditAnywhere)
	ASkylineBuildingDragBox BoxAbove;



	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceComp.AddDisabler(this);
		
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleOnActivated");
		FauxPhysicsTranslateComponent.OnConstraintHit.AddUFunction(this, n"HandleConstrainHit");
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"HandleReleased");

		ImpCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleGroundImpact");
		ImpCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"HandleGroundLeave");

		if(bIsLockedBox)
		{
			GravityWhipTargetComponent.Disable(this);
		}

		if(bIsFakeBox)
		{
			FauxPhysicsTranslateComponent.MinX = -700;
		}
	}

	UFUNCTION()
	private void HandleGroundLeave(AHazePlayerCharacter Player)
	{
		if(Player==Game::Zoe)
		{
			BoxAbove.GravityWhipTargetComponent.EnableForPlayer(Player, this);
		}
	}

	UFUNCTION()
	private void HandleGroundImpact(AHazePlayerCharacter Player)
	{
		if(Player==Game::Zoe)
		{
			BoxAbove.GravityWhipTargetComponent.DisableForPlayer(Player, this);
		}
	}

	UFUNCTION()
	private void HandleOnActivated(AActor Caller)
	{
		GravityWhipTargetComponent.Enable(this);
		bIsLockedBox = false;
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent,
	                           UGravityWhipTargetComponent TargetComponent,
	                           TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		USkylineBuildingDragBoxEventHandler::Trigger_OnFurnitureMove(this);
		
		ReturnForceComp.AddDisabler(this);

		if(FauxPhysicsTranslateComponent.RelativeLocation.X > -2.0)
		{
			FauxPhysicsTranslateComponent.ApplyImpulse(FauxPhysicsTranslateComponent.RelativeLocation, FauxPhysicsTranslateComponent.ForwardVector * -1600.0);
		}

		Timer::ClearTimer(this, n"PausePhysicsSimulation");

		FurnitureMeshComp1.SetSimulatePhysics(true);
		FurnitureMeshComp2.SetSimulatePhysics(true);
		FurnitureMeshComp3.SetSimulatePhysics(true);
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent,
	                            UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		USkylineBuildingDragBoxEventHandler::Trigger_OnStopMoving(this);
		ReturnForceComp.RemoveDisabler(this);
		Timer::SetTimer(this, n"PausePhysicsSimulation", 2.0);
	}

	UFUNCTION()
	private void PausePhysicsSimulation()
	{
		FurnitureMeshComp1.SetSimulatePhysics(false);
		FurnitureMeshComp2.SetSimulatePhysics(false);
		FurnitureMeshComp3.SetSimulatePhysics(false);

		FurnitureMeshComp1.AttachToComponent(FauxPhysicsTranslateComponent, NAME_None, EAttachmentRule::KeepWorld);
		FurnitureMeshComp2.AttachToComponent(FauxPhysicsTranslateComponent, NAME_None, EAttachmentRule::KeepWorld);
		FurnitureMeshComp3.AttachToComponent(FauxPhysicsTranslateComponent, NAME_None, EAttachmentRule::KeepWorld);
	}

	UFUNCTION()
	private void HandleConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		FSkylineBuildingDragBoxConstrainHit ConstrainHitStrength;
		ConstrainHitStrength.HitStrength = HitStrength;		
		
		if(Edge == EFauxPhysicsTranslateConstraintEdge::AxisX_Max)
		{
			USkylineBuildingDragBoxEventHandler::Trigger_OnConstrainHitLowAlpha(this, ConstrainHitStrength);
		}

		if(Edge == EFauxPhysicsTranslateConstraintEdge::AxisX_Min)
		{
			USkylineBuildingDragBoxEventHandler::Trigger_OnConstrainHitHighAlpha(this, ConstrainHitStrength);
		}

		if(!bIsFakeBox)
		{
			return;
		}	
	

		if(Edge == EFauxPhysicsTranslateConstraintEdge::AxisX_Min)
		{
			ReturnForceComp.AddDisabler(this);
			ForceComp.RemoveDisabler(this);
			FauxPhysicsTranslateComponent.ApplyImpulse(FauxPhysicsTranslateComponent.RelativeLocation, FauxPhysicsTranslateComponent.ForwardVector * -3000.0);
			GravityWhipTargetComponent.Disable(this);
			FauxPhysicsTranslateComponent.bConstrainZ = false;
			FauxPhysicsTranslateComponent.bConstrainX = false;
			GravityWhipTargetComponent.Disable(this);
		}

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}


};