class ASanctuaryCatapult : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UDarkPortalTargetComponent DarkPortalTargetComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpCallbackComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComp;

	UPROPERTY(DefaultComponent)
	UArrowComponent LaunchArrow;

	UPROPERTY(EditAnywhere)
	float ImpulseForce = 800.0;

	UPROPERTY(EditAnywhere)
	float GrabbedFriction = 33.0;

	FVector LaunchDirection;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UBoxComponent Trigger;
	default Trigger.BoxExtent = FVector(50.0, 50.0, 50.0,);
	default Trigger.bGenerateOverlapEvents = false;
	default Trigger.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default Trigger.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	//audio

	UPROPERTY(DefaultComponent, NotVisible, Attach = (RotateComp))
	UHazeAudioComponent AudioComp;	

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UHazeAudioEvent GrabbedEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UHazeAudioEvent ReleaseEvent;

	FHazeAudioPostEventInstance GrabbedEventInstance;
	FHazeAudioPostEventInstance ReleasedEventInstance;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		RotateComp.OnMinConstraintHit.AddUFunction(this, n"HandleMinConstraintHit");
		DarkPortalResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		DarkPortalResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		RotateComp.Friction = GrabbedFriction;

		auto Emitter = AudioComp.GetEmitter(this);
	
		Emitter.SetAttenuationScaling(8000);
		GrabbedEventInstance = Emitter.PostEvent(GrabbedEvent);

		FHazeAudioSeekData SeekData;
		SeekData.SeekType = EHazeAudioSeekType::Percentage;
		SeekData.SeekPosition = Math::Min(0.9, RotateComp.GetCurrentAlphaBetweenConstraints());

		GrabbedEventInstance.Seek(SeekData);
	}

	UFUNCTION()
	private void HandleReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		RotateComp.Friction = .35;

		GrabbedEventInstance.Stop(500, EAkCurveInterpolation::Log1);
		auto Emitter = AudioComp.GetEmitter(this);
		ReleasedEventInstance = Emitter.PostEvent(ReleaseEvent);

		FHazeAudioSeekData SeekData;
		SeekData.SeekType = EHazeAudioSeekType::Percentage;
		SeekData.SeekPosition = Math::Max(0, 0.8 - (RotateComp.GetCurrentAlphaBetweenConstraints() + 0.6));

		ReleasedEventInstance.Seek(SeekData);
	}

	UFUNCTION()
	private void HandleMinConstraintHit(float Strength)
	{
		//PrintToScreen("HitSrength" + Strength, 2.0);
		if(Strength>2.0)
		{
			Launch(Strength);
		}
		
	}

	void Launch(float HitStrength)
	{
		if (IsActorDisabled() || IsHidden())
			return;
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

		auto Trace = Trace::InitFromPrimitiveComponent(Trigger);
		auto Overlaps = Trace.QueryOverlaps(Trigger.WorldLocation);

		for (auto Overlap : Overlaps)
		{
			auto Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if (Player != nullptr)
			{
				LaunchDirection = LaunchArrow.GetForwardVector();
				float TweakedForce = ImpulseForce + (Math::GetMappedRangeValueClamped(FVector2D(0.02, 1.0), FVector2D(0.0, 100.0), Network::PingRoundtripSeconds));
				FVector Impulse = LaunchDirection * (TweakedForce * HitStrength);

				FPlayerLaunchToParameters LaunchParams;
				LaunchParams.Duration = 0.5;
				LaunchParams.LaunchImpulse = Impulse;
				LaunchParams.Type = EPlayerLaunchToType::LaunchWithImpulse;

				// Zoe controls the catapult, so can do a crumbed launch, because it will be synced with the catapult.
				// Mio does a simulated one so Zoe can see Mio launch when she releases
				if (Player.IsZoe())
					LaunchParams.NetworkMode = EPlayerLaunchToNetworkMode::Crumbed;
				else
					LaunchParams.NetworkMode = EPlayerLaunchToNetworkMode::SimulateLocal;
				Player.LaunchPlayerTo(this, LaunchParams);

				Player.FlagForLaunchAnimations(Impulse);
				//Player.AddMovementImpulse(LaunchDirection * 3000);

				PrintToScreen("Tweakfoce: " + TweakedForce, 3.0);
				PrintToScreen("PING: " + Network::PingRoundtripSeconds, 3.0);
			}
		}
	}


};