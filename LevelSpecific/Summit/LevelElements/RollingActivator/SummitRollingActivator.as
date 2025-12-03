struct FSummitRollingActivatorActivationParams
{
	UPROPERTY()
	AHazePlayerCharacter PlayerInstigator;

	UPROPERTY()
	float RollSpeed;
}

event void ESummitRollingActivatorOnActivated(FSummitRollingActivatorActivationParams Params);

class ASummitRollingActivator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BaseMeshComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.MaxX = 0.0;
	default TranslateComp.MinX = -1000.0;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.ConstrainBounce = 0.2;
	default TranslateComp.SpringStrength = 20.0;
	default TranslateComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent RollHitMesh;

	UPROPERTY(DefaultComponent, Attach = RollHitMesh)
	UTeenDragonTailAttackResponseComponent ResponseComp;
	default ResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent, Attach = RollHitMesh)
	UTeenDragonRollAutoAimComponent RollAutoAimComp;
	default RollAutoAimComp.bOnlyValidIfAimOriginIsWithinAngle = true;
	default RollAutoAimComp.MaxAimAngle = 60.0;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent CylinderMesh;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MoveAmount = 500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float FauxRollImpulse = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ActivationDelay = 0.2;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bOneUse = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bMetalIsBlocking = false;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = bMetalIsBlocking, EditConditionHides))
	ANightQueenMetal MetalBlocking;

	UPROPERTY()
	ESummitRollingActivatorOnActivated OnActivated;

	float TimeLastHitByRoll;
	float LastFrameAlpha = 0.0;
	bool bIsActivating = false;
	bool bIsBlockedByMetal = false;
	bool bHasReachedMax = false;
	bool bHasReset = false;
	bool bHasBeenUsed = false;

	FSummitRollingActivatorActivationParams LastActivationParams;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TranslateComp.OverrideNetworkSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		ResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		if(bMetalIsBlocking)
		{
			bIsBlockedByMetal = true;
			MetalBlocking.OnNightQueenMetalMelted.AddUFunction(this, n"OnMetalMelted");
			MetalBlocking.OnNightQueenMetalRecovered.AddUFunction(this, n"OnMetalRecovered");
		}
	}

	UFUNCTION()
	private void OnMetalMelted()
	{
		bIsBlockedByMetal = false;
	}

	UFUNCTION()
	private void OnMetalRecovered()
	{
		bIsBlockedByMetal = true;
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if(bOneUse
		&& bHasBeenUsed)
			return;

		if(bIsBlockedByMetal)
			return;

		if(Params.RollDirection.DotProduct(TranslateComp.ForwardVector) > 0)
			return;
		
		FVector Impulse = -TranslateComp.ForwardVector * FauxRollImpulse - TranslateComp.GetVelocity();
		FauxPhysics::ApplyFauxImpulseToActor(this, Impulse);
		
		TimeLastHitByRoll = Time::GameTimeSeconds;
		bIsActivating = true;
		bHasReachedMax = false;
		bHasReset = false;

		bHasBeenUsed = true;

		FSummitRollingActivatorActivationParams NewActivatorParams;
		NewActivatorParams.RollSpeed = Params.SpeedTowardsImpact;
		NewActivatorParams.PlayerInstigator = Params.PlayerInstigator;
		LastActivationParams = NewActivatorParams;

		USummitRollingActivatorEventHandler::Trigger_OnHit(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto TempLog = TEMPORAL_LOG(this);

		if(bIsActivating)
		{
			if(Time::GetGameTimeSince(TimeLastHitByRoll) <= ActivationDelay)
			{
				OnActivated.Broadcast(LastActivationParams);
				bIsActivating = false;

				USummitRollingActivatorEventHandler::Trigger_OnActivated(this);
			}
		}

		float TranslateCompAlpha = TranslateComp.GetCurrentAlphaBetweenConstraints().X;
		if(!bHasReachedMax)
		{
			if(TranslateCompAlpha > LastFrameAlpha)
			{
				USummitRollingActivatorEventHandler::Trigger_OnReachedFurthestIn(this);
				bHasReachedMax = true;
				TempLog.Event("Reached Furthest In");
			}
		}
		else if(!bHasReset)
		{
			if(Math::IsNearlyEqual(TranslateCompAlpha, LastFrameAlpha, 0.01))
			{
				USummitRollingActivatorEventHandler::Trigger_OnReset(this);
				bHasReset = true;
				TempLog.Event("Reset");
			}
		}
		LastFrameAlpha = TranslateComp.GetCurrentAlphaBetweenConstraints().X;

		TempLog
			.Value("Last Frame Alpha", LastFrameAlpha)
		;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TranslateComp.MinX = -MoveAmount;
		TranslateComp.MaxX = 0;
	}
};