event void FOnSkylineAllyOnSunBlockerPlayerBounce(AHazePlayerCharacter Player);



class ASkylineAllyBouncySunBlocker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent CollisionComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent BounceEvent = nullptr;

	UPROPERTY(EditAnywhere, Category = "Audio", Meta = (EditCondition = "BounceEvent != nullptr"))
	FHazeAudioFireForgetEventParams Params;	
	default Params.Transform = CollisionComp.GetWorldTransform();

	UPROPERTY()
	FHazeTimeLike RevealTimeLike;
	default RevealTimeLike.UseSmoothCurveZeroToOne();
	default RevealTimeLike.Duration = 0.3;

	UPROPERTY()
	float RetractDelay = 2.0;

	bool bActivated;

	UPROPERTY()
	FOnSkylineAllyOnSunBlockerPlayerBounce OnPlayerBounce;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");
		ImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleHit");
		ForceComp.AddDisabler(this);
	}

	UFUNCTION()
	private void HandleHit(AHazePlayerCharacter Player)
	{
		PrintToScreenScaled("BlockerHit", 3.0);

		Player.AddMovementImpulseToReachHeight(1000.0);
		Player.FlagForLaunchAnimations(FVector(0.0,0.0,1000));
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

		if(BounceEvent != nullptr)
		{
			AudioComponent::PostFireForget(BounceEvent, Params);
		}

		OnPlayerBounce.Broadcast(Player);

	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		BPActivated();
		bActivated = true;
		ForceComp.RemoveDisabler(this);
		TranslateComp.SpringStrength = 0.0;
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		bActivated = false;
		BPDeactivated();
		Timer::SetTimer(this, n"Retract", RetractDelay);
	}

	UFUNCTION()
	private void Retract()
	{
		if (bActivated)
			return;

		RevealTimeLike.Reverse();
		ForceComp.AddDisabler(this);
		TranslateComp.SpringStrength = 2.0;
	}

	UFUNCTION(BlueprintEvent)
	private void BPActivated()
	{
	}

	UFUNCTION(BlueprintEvent)
	private void BPDeactivated()
	{
	}
}