event void FASummitTailWeighDownElevatorWeightSignature();

class ASummitTailWeighDownElevatorWeight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.MinZ = -300;
	default TranslateComp.SpringStrength = 5.0;
	default TranslateComp.Friction = 1.5;
	default TranslateComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromZoeControl;
	default TranslateComp.OverrideNetworkSyncRate(EHazeCrumbSyncRate::PlayerSynced);

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent WeightMesh;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent ClimbableMesh;
	default ClimbableMesh.ComponentTags.Add(n"TailDragonClimbable");

	UPROPERTY(DefaultComponent, Attach = ClimbableMesh)
	UBabyDragonTailClimbFreeFormResponseComponent ResponseComp;
	default ResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 30000.0;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PlayerAttachedForce = 200.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float WeighDownDistanceMax = 300.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	TSubclassOf<UCameraShakeBase> ConstraintHitShake;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UForceFeedbackEffect ConstraintHitRumble;

	bool bPlayerIsAttached = false;
	float SpringStrength;

	UPROPERTY(DefaultComponent)
	USceneComponent SteamFXLocation;

	UPROPERTY()
	UNiagaraSystem SteamEffect;

	UPROPERTY()
	FASummitTailWeighDownElevatorWeightSignature OnWeighingDown;

	UPROPERTY()
	FASummitTailWeighDownElevatorWeightSignature OnWeighingStopped;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TranslateComp.MinZ = -WeighDownDistanceMax;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnTailAttached.AddUFunction(this, n"OnTailAttached");
		ResponseComp.OnTailReleased.AddUFunction(this, n"OnTailReleased");
		ResponseComp.OnTailJumpedFrom.AddUFunction(this, n"OnTailJumpedFrom");

		SpringStrength = TranslateComp.SpringStrength;

		TranslateComp.OnConstraintHit.AddUFunction(this, n"OnConstraintHit");

		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION()
	private void OnConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		USummitTailWeighDownElevatorWeightEventHandler::Trigger_OnHitConstraint(this);

		for(auto Player : Game::Players)
		{
			const float InnerConstraintFeedbackRadius = 300.0;
			const float OuterConstraintFeedbackRadius = 500.0;
			Player.PlayWorldCameraShake(ConstraintHitShake, this, ClimbableMesh.WorldLocation, InnerConstraintFeedbackRadius, OuterConstraintFeedbackRadius);

			float DistToPlayer = ClimbableMesh.WorldLocation.Distance(Player.ActorLocation);
			float DistAlpha = Math::GetPercentageBetweenClamped(OuterConstraintFeedbackRadius, InnerConstraintFeedbackRadius, DistToPlayer);
			Player.PlayForceFeedback(ConstraintHitRumble, false, false, this, DistAlpha);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bPlayerIsAttached)
		{
			FauxPhysics::ApplyFauxForceToActor(this, FVector::DownVector * PlayerAttachedForce);
		}
	}

	float GetWeighedDownAlpha() const property
	{
		return TranslateComp.GetCurrentAlphaBetweenConstraints().Z;
	}

	UFUNCTION()
	private void OnTailAttached(FBabyDragonTailClimbFreeFormAttachParams Params)
	{
		bPlayerIsAttached = true;
		TranslateComp.SpringStrength = 0.0;
		
		USummitTailWeighDownElevatorWeightEventHandler::Trigger_OnStartedWeighingDown(this);
		OnWeighingDown.Broadcast();
		BP_OnTailAttached();
	}

	UFUNCTION()
	private void OnTailReleased(FBabyDragonTailClimbFreeFormReleasedParams Params)
	{
		bPlayerIsAttached = false;
		TranslateComp.SpringStrength = SpringStrength;

		USummitTailWeighDownElevatorWeightEventHandler::Trigger_OnStoppedWeighingDown(this);
		OnWeighingStopped.Broadcast();
		BP_OnTailReleased();
	}

	UFUNCTION()
	private void OnTailJumpedFrom(FBabyDragonTailClimbFreeFormJumpedFromParams Params)
	{
		bPlayerIsAttached = false;
		TranslateComp.SpringStrength = SpringStrength;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnTailAttached(){
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnTailReleased(){
	}
};