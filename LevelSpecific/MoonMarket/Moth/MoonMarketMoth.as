event void FOnMoonMarketBookUsed();

class AMoonMarketMoth : AHazeActor
{
	UPROPERTY()
	FOnMoonMarketBookUsed OnMoonMarketBookUsed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent AppearEffect;
	default AppearEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	private UMoonMarketPlayerRideMothComponent RiderPlayer;

	UPROPERTY()
	UMoonMarketMothFlyingSettings Settings;

	UPROPERTY(DefaultComponent, Attach = MeshComp, AttachSocket = "Base")
	UInteractionComponent InteractionComp;
	default InteractionComp.ActionShape.Type = EHazeShapeType::Sphere;
	default InteractionComp.bUseLazyTriggerShapes = true;
	default InteractionComp.MovementSettings.Type = EMoveToType::SmoothTeleport;
	default InteractionComp.bShowCancelPrompt = false;
	default InteractionComp.bPlayerCanCancelInteraction = false;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	AMoonMarketMothSpline Spline;

	UPROPERTY(DefaultComponent, EditDefaultsOnly)
	UNiagaraComponent NiagaraDisintegrateComp;

	UPROPERTY(EditInstanceOnly)
	bool bStartDisabled = false;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DisintegrateOneshot;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FX_Trail;
	default FX_Trail.SetAutoActivate(false);

	UPROPERTY(EditInstanceOnly)
	TArray<ADeathVolume> DeathVolumes;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SidewaysDistance;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent CurrentTiltValue;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent TargetTiltValue;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVector2DComponent SteerInput;

	UPROPERTY(DefaultComponent)
	UMoonMarketCatProgressComponent ProgressComp;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;

	FSplinePosition CurrentSplinePosition;
	float CurrentSplineSpeed;
	FVector PreviousSidewaysWorldOffset;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams AnimGlide;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams AnimHover;

	AActor OriginalAttachParent;
	FTransform OriginalRelativeTransform;

	bool bHasBeenRidden = false;
	bool bHasSpawned = false;
	float StartRidingTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalAttachParent = AttachParentActor;
		OriginalRelativeTransform = ActorRelativeTransform;
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
		InteractionComp.Disable(this);
		NiagaraDisintegrateComp.SetFloatParameter(n"SpawnRate", 0);
		if (bStartDisabled)
			AddActorDisable(this);
		ProgressComp.OnProgressionActivated.AddUFunction(this, n"OnProgressionActivated");
	}

	void Reset()
	{
		Spline.Spline.SplinePoints[0].RelativeLocation = Spline.Spline.WorldTransform.InverseTransformPosition(ActorLocation);
		Spline.Spline.UpdateSpline();
		CurrentSplinePosition = Spline.Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
		PreviousSidewaysWorldOffset = FVector::ZeroVector;
		SidewaysDistance.Value = 0;
		CurrentTiltValue.Value = 0;
		CurrentSplineSpeed = 0;
	}

	UFUNCTION()
	private void OnProgressionActivated()
	{
		ActivateMothAppearance();
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		Respawn();
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{		
		RiderPlayer = UMoonMarketPlayerRideMothComponent::Get(Player);
		RiderPlayer.Moth = this;
		bHasBeenRidden = true;

		InteractionComp.Disable(this);
		StartRidingTime = Time::GameTimeSeconds;
		FX_Trail.Activate(true);

		DetachFromActor(EDetachmentRule::KeepWorld);

		SetActorControlSide(RiderPlayer);

		MeshComp.PlaySlotAnimation(AnimGlide);

		Reset();

		SetDeathVolumeCanKillPlayer(RiderPlayer.Player, false);
		OnMoonMarketBookUsed.Broadcast();
		UMoonMarketMothEventHandler::Trigger_OnStartRiding(this, FMoonMarketInteractingPlayerEventParams(Player));
	}

	UMoonMarketPlayerRideMothComponent GetRider() const
	{
		return RiderPlayer;
	}

	void ThrowOffRider()
	{
		//Niagara::SpawnOneShotNiagaraSystemAtLocation(DisintegrateOneshot, ActorLocation);
		
		if(RiderPlayer != nullptr)
		{
			RiderPlayer.Player.ResetMovement();
			RiderPlayer.Player.DetachFromActor();
			RiderPlayer.Player.SetActorHorizontalVelocity(ActorHorizontalVelocity);
			SetDeathVolumeCanKillPlayer(RiderPlayer.Player, true);
			RiderPlayer.Moth = nullptr;
			RiderPlayer = nullptr;
		}

		InteractionComp.KickAnyPlayerOutOfInteraction();
		Respawn();
	}

	UFUNCTION(DevFunction)
	void ActivateMothAppearance()
	{
		RemoveStartDisable();
		AppearEffect.Activate();
	}

	void FinishSpawning()
	{
		bHasSpawned = true;
		InteractionComp.Enable(this);
	}

	UFUNCTION()
	void RemoveStartDisable()
	{
		RemoveActorDisable(this);
	}

	bool IsBeingRidden() const
	{
		return RiderPlayer != nullptr;
	}
	
	FHitResult TraceForWall() const
	{
		FHazeTraceSettings TraceSettings = Trace::InitObjectType(EObjectTypeQuery::WorldStatic);
		TraceSettings.UseLine();
		TraceSettings.IgnoreActor(this);

		const FVector Start = ActorLocation + FVector::UpVector * 50;
		const float TraceDistance = 300;
		const FVector End = Start + ActorForwardVector * TraceDistance + FVector::UpVector * 50;
		FHitResult ForwardHit = TraceSettings.QueryTraceSingle(Start, End);

		return ForwardHit;
	}

	void Disable()
	{
		AddActorCollisionBlock(this);
		AddActorVisualsBlock(this);
	}

	void Respawn()
	{
		AttachToActor(OriginalAttachParent);
		SetActorRelativeTransform(OriginalRelativeTransform);
		InteractionComp.Enable(this);
		bHasBeenRidden = false;
		bHasSpawned = false;
		if(FX_Trail != nullptr){
			FX_Trail.Deactivate();
		}
		RemoveActorVisualsBlock(this);
		RemoveActorCollisionBlock(this);

		MeshComp.PlaySlotAnimation(AnimGlide);
	}

	void SetDeathVolumeCanKillPlayer(AHazePlayerCharacter Player, bool bCanKill)
	{
		for (ADeathVolume Volume : DeathVolumes)
		{
			if (Player.IsMio())
				Volume.bKillsMio = bCanKill;
			else
				Volume.bKillsZoe = bCanKill;
		}
	}
};