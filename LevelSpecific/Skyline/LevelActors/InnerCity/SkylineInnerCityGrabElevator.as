UCLASS(Abstract)
class USkylineInnerCityGrabElevatorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrabbed()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReleased()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitGround()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitTop()
	{
	}

};
class ASkylineInnerCityGrabElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceCompReset;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceCompGlide;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent GravityWhipOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpCallbackComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;


	bool bHasHitConstrain;
	bool bIsLocked;
	bool bIsAtBottom = false;
	float StartingConstrainMaxZ;
	float StartingConstrainMinZ;

	bool bIsGoingDown = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"HandleReleased");
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");

		ImpCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleGroundImpact");
		ImpCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"HandleGroundLeave");

		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstrainHit");
		
		ForceCompGlide.AddDisabler(this);
		ForceCompReset.AddDisabler(this);
		StartingConstrainMaxZ = TranslateComp.MaxZ;
		StartingConstrainMinZ = TranslateComp.MinZ;
		TranslateComp.MaxZ = 10.0;
		TranslateComp.MinZ = 10.0;
		
	}



	UFUNCTION()
	private void HandleConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Max)
		{
			USkylineInnerCityGrabElevatorEventHandler::Trigger_OnHitTop(this);	
		}

		if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Min)
		{
			ForceCompReset.AddDisabler(this);
			bIsGoingDown = false;
			USkylineInnerCityGrabElevatorEventHandler::Trigger_OnHitGround(this);
		}

		if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Min && HitStrength > 500.0)
		{
			CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		}
			
	}

	UFUNCTION()
	private void HandleResetHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(!bIsAtBottom)
		{
			ForceCompReset.RemoveDisabler(this);
			bIsAtBottom = true;
		}
			
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		TranslateComp.MaxZ = 10.0;
		TranslateComp.MinZ = 10.0;
		ForceCompGlide.AddDisabler(this);
		ForceCompReset.AddDisabler(this);
		bIsLocked = true;
		//GravityWhipTargetComponent.Disable(this);
		
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		auto Reset = Cast<ASkylineInnerCityGrabElevatorReset>(Caller);
		if (Reset != nullptr)
		{
			if(!bIsAtBottom)
			{
				ForceCompReset.RemoveDisabler(this);
				bIsAtBottom = true;
			}			
		}

		bIsLocked = false;
		ForceCompGlide.RemoveDisabler(this);
		TranslateComp.MaxZ = StartingConstrainMaxZ; 
		TranslateComp.MinZ = StartingConstrainMinZ;
		//GravityWhipTargetComponent.Enable(this);
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent,
	                           UGravityWhipTargetComponent TargetComponent,
	                           TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		ForceCompReset.AddDisabler(this);
		bIsAtBottom = false;
		bIsGoingDown = true;
		USkylineInnerCityGrabElevatorEventHandler::Trigger_OnGrabbed(this);
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent,
	                            UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		USkylineInnerCityGrabElevatorEventHandler::Trigger_OnReleased(this);
	}

	UFUNCTION()
	private void HandleGroundImpact(AHazePlayerCharacter Player)
	{
		if(Player==Game::Zoe)
		{
			GravityWhipTargetComponent.DisableForPlayer(Player, this);							
		}	
	}

		UFUNCTION()
	private void HandleGroundLeave(AHazePlayerCharacter Player)
	{
		if(Player==Game::Zoe)
		{
			GravityWhipTargetComponent.EnableForPlayer(Player, this);							
		}	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		float FFFrequency = 30.0;
		float FFIntensity = 0.6;
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * FFFrequency) * FFIntensity;
		FF.RightMotor = Math::Sin(-Time::GameTimeSeconds * FFFrequency) * FFIntensity;

		if(!GravityWhipResponseComponent.IsGrabbed() && !bIsLocked && bIsGoingDown)
			ForceFeedback::PlayWorldForceFeedbackForFrame(FF, TranslateComp.WorldLocation, 300, 400, 1.0, EHazeSelectPlayer::Both);
	
	}
};