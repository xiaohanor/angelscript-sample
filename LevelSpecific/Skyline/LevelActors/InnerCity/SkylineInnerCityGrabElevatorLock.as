UCLASS(Abstract)
class USkylineInnerCityGrabElevatorLockEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLocked()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUnLocked()
	{
	}

};
class ASkylineInnerCityGrabElevatorLock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LockMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot1;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot2;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot3;

	UPROPERTY(DefaultComponent)
	USceneComponent SceneComp;

	UPROPERTY(DefaultComponent)
	USceneComponent SceneComp2;

	UPROPERTY(DefaultComponent, Attach = Pivot3)
	UGravityBladeCombatTargetComponent GravityBladeTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityBladeTargetComponent)
	UTargetableOutlineComponent GravityBladeOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent GravityBladeResponseComponent;
	default GravityBladeResponseComponent.InteractionType = EGravityBladeCombatInteractionType::VerticalUp;

//	UPROPERTY(DefaultComponent)
//	UGravityBladeCombatInteractionResponseComponent CombatInteractionResponseComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComponent;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike Timelike;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem SparkVFX;

	UPROPERTY(EditInstanceOnly)
	ASkylineInnerCityGrabElevator Elevator;

	UPROPERTY(EditAnywhere)
	bool bIsLocked = true;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpCallbackComp;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Timelike.BindUpdate(this, n"HandleAnimationUpdate1");
		
		InterfaceComponent.OnActivated.AddUFunction(this, n"HandleActivated");
		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"HandleBladeHit");

		ImpCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleGroundImpact");
		ImpCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"HandleGroundLeave");
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		if(bIsLocked)
		{
			Timelike.Play();
			HandleMaterialChange();
			InterfaceComponent.TriggerActivate();
			bIsLocked=false;
			GravityBladeResponseComponent.InteractionType = EGravityBladeCombatInteractionType::VerticalDown;
		}
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(bIsLocked)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(SparkVFX, SceneComp.GetWorldLocation());
			Niagara::SpawnOneShotNiagaraSystemAtLocation(SparkVFX, SceneComp2.GetWorldLocation());
			InterfaceComponent.TriggerActivate();
			Timelike.Play();
			GravityBladeResponseComponent.InteractionType = EGravityBladeCombatInteractionType::VerticalDown;
			HandleMaterialChange();
			bIsLocked=false;
			USkylineInnerCityGrabElevatorLockEventHandler::Trigger_OnUnLocked(this);
		}else{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(SparkVFX, SceneComp.GetWorldLocation());
			Niagara::SpawnOneShotNiagaraSystemAtLocation(SparkVFX, SceneComp2.GetWorldLocation());
			InterfaceComponent.TriggerDeactivate();
			Timelike.Reverse();
			GravityBladeResponseComponent.InteractionType = EGravityBladeCombatInteractionType::VerticalUp;
			HandleMaterialChange();
			bIsLocked=true;	
			USkylineInnerCityGrabElevatorLockEventHandler::Trigger_OnLocked(this);
		}
	}

	UFUNCTION()
	private void HandleAnimationUpdate1(float CurrentValue)
	{
		Pivot1.RelativeRotation = FRotator(0.0, CurrentValue * -40, 0.0);
		Pivot2.RelativeRotation = FRotator(0.0, CurrentValue * 40, 0.0);
		Pivot3.RelativeLocation = FVector(0.0, 0.0, CurrentValue * 70);
	}

	UFUNCTION(BlueprintEvent)
	void HandleMaterialChange()
	{
		
	}

	UFUNCTION()
	private void HandleGroundImpact(AHazePlayerCharacter Player)
	{
		if(Player==Game::Zoe)
		{
			Elevator.GravityWhipTargetComponent.DisableForPlayer(Player, this);							
		}	
	}

		UFUNCTION()
	private void HandleGroundLeave(AHazePlayerCharacter Player)
	{
		if(Player==Game::Zoe)
		{
			Elevator.GravityWhipTargetComponent.EnableForPlayer(Player, this);							
		}	
	}
};