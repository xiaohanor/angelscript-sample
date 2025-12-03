class AWitchBouncyMushroomActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshScalerDefault;

	UPROPERTY(DefaultComponent, Attach = MeshScalerDefault)
	USceneComponent MeshScalerAnimation;
	
	UPROPERTY(DefaultComponent, Attach = MeshScalerAnimation)
	UStaticMeshComponent Mesh;
	default Mesh.RemoveTag(ComponentTags::LedgeClimbable);
	default Mesh.RemoveTag(ComponentTags::LedgeRunnable);

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditAnywhere)
	float BounceStrength = 3000;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve  HeightAnimationCurve;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve WidthAnimationCurve;

	UPROPERTY(EditDefaultsOnly)
	float Intensity = 1.0;

	float TimeSinceBounce = 1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"Bounce");
	}

	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TimeSinceBounce += DeltaSeconds;
		TimeSinceBounce = Math::Clamp(TimeSinceBounce, 0, 1);

		float Width = WidthAnimationCurve.GetFloatValue(TimeSinceBounce);
		float Height = HeightAnimationCurve.GetFloatValue(TimeSinceBounce);
		MeshScalerAnimation.SetRelativeScale3D(FVector(Width, Width, Height));
	}

	UFUNCTION()
	void Bounce(AHazePlayerCharacter Player)
	{
		if(UMoonMarketShapeshiftComponent::Get(Player).IsShapeshiftActive())
		{
			if(Cast<AMoonMarketThunderCloud>(UMoonMarketShapeshiftComponent::Get(Player).GetShape()) != nullptr)
				return;
		}

		TimeSinceBounce = 0;
		auto MushroomBounceComp = UWitchPlayerMushroomBounceComponent::Get(Player);

		if(MushroomBounceComp != nullptr)
		{
			MushroomBounceComp.BounceFrame = Time::FrameNumber;
			MushroomBounceComp.BounceTime = Time::GameTimeSeconds;
		}
		
		//Player.PlayCameraShake(CameraShake, this, Intensity);
		UMoonMarketMushroomPeopleEventHandler::Trigger_OnBouncedOn(this);
		Player.PlayForceFeedback(ForceFeedback, false, false, this, Intensity);

		Player.SetActorVerticalVelocity(FVector::ZeroVector);
		Player.ResetMovement();
		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		//Give less of a boost if player is in balloon form
		if(UMoonMarketBalloonPotionComponent::Get(Player).IsBalloonFormActive())
			Player.AddPlayerLaunchMovementImpulse(FVector::UpVector * BounceStrength * 0.5);
		else
			Player.AddPlayerLaunchMovementImpulse(FVector::UpVector * BounceStrength);
	}
};