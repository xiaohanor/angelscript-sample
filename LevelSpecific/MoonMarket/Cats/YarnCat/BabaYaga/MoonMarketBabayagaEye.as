class AMoonMarketBabayagaEye : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent MeshOffset;

	UPROPERTY(DefaultComponent, Attach = MeshOffset)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent InnerEyelidUpper;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent InnerEyelidLower;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	
	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve BlinkCurve;

	bool bEyeOpen = false;
	float BlinkTime = 0;
	float BlinkSpeed = 0.75;
	const float BlinkCurveLength = 7.9 / BlinkSpeed;

	UPROPERTY(EditAnywhere)
	float ReactionDistance = 700;

	UPROPERTY(EditAnywhere)
	const float FieldOfView = 80;

	UPROPERTY(EditAnywhere)
	const float MaxEyeFollowAngle = 40;

	UPROPERTY(EditAnywhere)
	const float MaxLookAroundAngle = 30;

	UPROPERTY(EditAnywhere)
	const float MinTimeBetweenLook = 0.5;

	UPROPERTY(EditAnywhere)
	const float MaxTimeBetweenLook = 2;

	UPROPERTY(EditAnywhere)
	const float ShakeFrequency = 7;

	UPROPERTY(EditAnywhere)
	const float ShakeStrength = 3;

	UPROPERTY(EditAnywhere)
	const float Snappiness = 1;

	FQuat OriginalRotation;
	FRotator TargetRotation;
	FHazeAcceleratedRotator AccRot;
	float TimeUntilLook = 0;

	bool bTargetingPlayer = false;
	
	bool bWasTargetingPlayer = false;
	bool bWasBlinking = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalRotation = RotationRoot.WorldRotation.Quaternion();
		AccRot.SnapTo(ActorRotation);
		MovementImpactCallbackComp.OnAnyImpactByPlayer.AddUFunction(this, n"ForceBlink");

		ABabaYagaGeoRootMover Babayaga = Cast<ABabaYagaGeoRootMover>(AttachParentActor);
		if(Babayaga != nullptr)
		{
			Babayaga.OnStartStanding.AddUFunction(this, n"OpenEye");
			Babayaga.OnStartStandingInstant.AddUFunction(this, n"OpenEye");
		}
	}

	UFUNCTION()
	private void ForceBlink(AHazePlayerCharacter Player)
	{
		if(Player.ActorVelocity.Size() < 25)
			return;

		if(IsBlinking())
			return;

		BlinkTime = 6;
	}

	bool IsBlinking() const
	{
		if(BlinkTime > 6 && BlinkTime < 6.5)
			return true;

		return false;
	}

	UFUNCTION(BlueprintEvent)
	private void OpenEye()
	{
	}

	UFUNCTION(BlueprintCallable)
	void SetEyeOpen()
	{
		bEyeOpen = true;
		BlinkTime = Math::RandRange(0, 5.5);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float RotationNoise1 = Math::Pow(ShakeStrength * Math::PerlinNoise1D(Time::GameTimeSeconds * ShakeFrequency), Snappiness);
		const float RotationNoise2 = Math::Pow(ShakeStrength * Math::PerlinNoise1D(100 + Time::GameTimeSeconds * ShakeFrequency), Snappiness);
		FRotator Offset = FRotator(RotationNoise1, RotationNoise2, 0);

		TArray<AHazePlayerCharacter> Players;
		Players.Add(Game::GetClosestPlayer(ActorLocation));
		Players.Add(Players.Last().OtherPlayer);
		
		bool bLookAtSuccess = false;
		for(auto Player : Players)
		{
			if(bLookAtSuccess)
				break;
			
			FVector PlayerLookAtLocation = Player.ActorLocation + FVector::UpVector * 120;

			if(PlayerLookAtLocation.DistSquared(ActorLocation) <= ReactionDistance * ReactionDistance)
			{
				FVector ToPlayer = (PlayerLookAtLocation - ActorLocation).GetSafeNormal();
				FQuat LookAtWorld = FQuat::MakeFromXZ(ToPlayer, OriginalRotation.UpVector);
				
				FRotator LookAtRelative = (OriginalRotation.Inverse() * LookAtWorld).Rotator();

				if(Math::Abs(LookAtRelative.Yaw) > FieldOfView)
					continue;

				if(Math::Abs(LookAtRelative.Pitch) > FieldOfView)
					continue;

				bLookAtSuccess = true;
				LookAtRelative.Pitch = Math::Clamp(LookAtRelative.Pitch, -MaxEyeFollowAngle, MaxEyeFollowAngle);
				LookAtRelative.Yaw = Math::Clamp(LookAtRelative.Yaw, -MaxEyeFollowAngle, MaxEyeFollowAngle);
				LookAtRelative.Roll = 0;

				LookAtWorld = OriginalRotation * LookAtRelative.Quaternion();

				AccRot.SpringTo(LookAtWorld.Rotator(), 200, 0.5, DeltaSeconds);
				const float ShakeMultiplier = 0.3;
				RotationRoot.SetWorldRotation(AccRot.Value + Offset * ShakeMultiplier);
			}
		}

		if(!bLookAtSuccess)
		{
			bWasTargetingPlayer = false;
			TimeUntilLook -= DeltaSeconds;
			if(TimeUntilLook <= 0)
			{
				TimeUntilLook = Math::RandRange(MinTimeBetweenLook, MaxTimeBetweenLook);
				TargetRotation = OriginalRotation.Rotator() + FRotator(Math::RandRange(-MaxLookAroundAngle, MaxLookAroundAngle), Math::RandRange(-MaxLookAroundAngle, MaxLookAroundAngle), 0);
			}

			AccRot.AccelerateTo(TargetRotation, 0.2, DeltaSeconds);
			RotationRoot.SetWorldRotation(AccRot.Value + Offset);
		}
		else
		{
			if(!bWasTargetingPlayer)
			{
				bWasTargetingPlayer = true;
				UMoonMarketBabaYagaEyeEventHandler::Trigger_OnTargetedPlayer(this);
			}
		}

		if(bEyeOpen)
		{
			BlinkTime += DeltaSeconds * BlinkSpeed;
			if(BlinkTime >= BlinkCurveLength)
			{
				BlinkTime -= BlinkCurveLength;
			}

			const float BlinkValue = BlinkCurve.GetFloatValue(BlinkTime);
			const float Yaw = RotationRoot.RelativeRotation.Yaw * 0.2;
			InnerEyelidUpper.SetRelativeRotation(FRotator(70 - BlinkValue * (90 - 20) + RotationRoot.RelativeRotation.Pitch * 0.25, Yaw, 180));
			InnerEyelidLower.SetRelativeRotation(FRotator(-60 + BlinkValue * (90 - 25) + RotationRoot.RelativeRotation.Pitch * 0.25, Yaw, 0));
		
			if(IsBlinking())
			{
				if(!bWasBlinking)
				{
					bWasBlinking = true;
					UMoonMarketBabaYagaEyeEventHandler::Trigger_OnBlink(this);
				}
			}
			else
			{
				bWasBlinking = false;
			}
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(ActorLocation, ReactionDistance);
	}
#endif
};