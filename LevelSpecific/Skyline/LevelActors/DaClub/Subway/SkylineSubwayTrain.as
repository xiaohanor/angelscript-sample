UFUNCTION(Category = "VFX", DisplayName = "Get Trains")
ASkylineSubwayTrain Gettrains()
{
     ASkylineSubwayTrain Trains = TListedActors<ASkylineSubwayTrain>().GetSingle();
	return Trains;
}

UFUNCTION(Category = "VFX", DisplayName = "Get Train")
TArray<ASkylineSubwayTrain> Gettrain()
{
    auto Trains = TListedActors<ASkylineSubwayTrain>().GetArray();
	return Trains;
}

event void FSkylineSubwayTrainSignature();

class ASkylineSubwayTrain : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent TrainPivot;

	UPROPERTY(DefaultComponent)
    UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent, Attach = TrainPivot)
	UBoxComponent BoxComp;
	default BoxComp.bGenerateOverlapEvents = false;
	default BoxComp.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = TrainPivot)
	UBoxComponent HornBox;
	default HornBox.bGenerateOverlapEvents = false;
	default HornBox.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = TrainPivot)
	UCapsuleComponent RumbleZone;

	UPROPERTY(EditAnywhere)
	float Distance = 120000.0;

	UPROPERTY(EditAnywhere)
	float Speed = 12000.0;

	UPROPERTY(EditAnywhere)
	float Offset = 0.0;

	UPROPERTY(EditAnywhere)
	bool bUseFixedTravelTime = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseFixedTravelTime"))
	float FixedTravelTime = 1.0;

	UPROPERTY(EditAnywhere)
	float TravelTime = 0.0;
	
	UPROPERTY(EditAnywhere)
	bool bShadowedLights = false;

	UPROPERTY(EditAnywhere)
	ASkylineSubwaySlide SubwaySlideGrapple;

	UPROPERTY(EditAnywhere)
	ASkylineSubwayWallRun WallRunGrapple;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	FCollisionShape CollisionShape;
	FCollisionShape HornShape;

	TPerPlayer<UPlayerGrappleComponent> PlayerGrappleComp;
	TPerPlayer<UPlayerSlideComponent> PlayerSlideComp;
	TPerPlayer<UPlayerWallRunComponent> PlayerWallRunComp;
	TPerPlayer<FHazeAcceleratedFloat> AccRumble;
	TPerPlayer<bool> bForcedSliding;
	TPerPlayer<bool> bInWallRun;

	bool bShouldHorn = true;
	bool bPlayerDodgeEvent = true;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditAnywhere)
	AFocusCameraActor SlideCamera;

	UPROPERTY(EditAnywhere)
	AFocusCameraActor WallRunCamera;

	UPROPERTY()
	FSkylineSubwayTrainSignature OnHorn;

	UPROPERTY()
	FSkylineSubwayTrainSignature OnPlayerDodge;

	UPROPERTY(DefaultComponent, Attach = TrainPivot)
	UHazeCameraComponent DeathCamera;

	TPerPlayer<bool> bKilledByTrain;
	TArray<USpotLightComponent> Spotlights;
	TArray<USpotLightComponent> ShadowedSpotlights;

	float ActionCameraTimeStamp = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TravelTime = Distance / Speed;

		if (bUseFixedTravelTime)
			TravelTime = FixedTravelTime;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TravelTime = Distance / Speed;

		if (bUseFixedTravelTime)
			TravelTime = FixedTravelTime;

		Offset = TravelTime * Offset;

		CollisionShape = BoxComp.GetCollisionShape();
		HornShape = HornBox.GetCollisionShape();

		for (auto Player : Game::Players)
		{
			PlayerGrappleComp[Player] = UPlayerGrappleComponent::Get(Player);
			PlayerSlideComp[Player] = UPlayerSlideComponent::Get(Player);
			PlayerWallRunComp[Player] = UPlayerWallRunComponent::Get(Player);
		}
		
		if(SubwaySlideGrapple != nullptr)
			SubwaySlideGrapple.GrapplePoint.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"HandleGrappleStarted");

		if(WallRunGrapple != nullptr)
			WallRunGrapple.GrapplePointRight.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"HandleGrappleStarted");

		GetComponentsByClass(Spotlights);
		if (!bShadowedLights)
		{
			for (USpotLightComponent Light : Spotlights)
			{
				Light.CastShadows = false;
				Light.MarkRenderStateDirty();
			}
		}
		else
		{
			for (USpotLightComponent Light : Spotlights)
			{
				if (Light.CastShadows)
				{
					ShadowedSpotlights.Add(Light);

					Light.CastShadows = false;
					Light.MarkRenderStateDirty();
				}
			}
		}
	}

	UFUNCTION()
	private void HandleGrappleStarted(AHazePlayerCharacter Player,
	                                  UGrapplePointBaseComponent TargetedGrapplePoint)
	{
		if(TargetedGrapplePoint==SubwaySlideGrapple.GrapplePoint)
			Player.ActivateCamera(SlideCamera, 1, this, EHazeCameraPriority::VeryHigh);

		if(TargetedGrapplePoint==WallRunGrapple.GrapplePointRight)
			Player.ActivateCamera(WallRunCamera, 1, this, EHazeCameraPriority::VeryHigh);
	
		ActionCameraTimeStamp = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{//
		if (bShadowedLights)
		{
			for (USpotLightComponent Light : ShadowedSpotlights)
			{
				float ClosestDistance = Game::GetDistanceFromLocationToClosestPlayer(Light.WorldLocation);
				bool bShouldShadow = ClosestDistance < 100000.0;
				if (Light.CastShadows != bShouldShadow)
				{
					Light.CastShadows = bShouldShadow;
					Light.MarkRenderStateDirty();
				}
			}
		}

		float Alpha = Math::Frac((Time::PredictedGlobalCrumbTrailTime + Offset) / TravelTime);
		TrainPivot.RelativeLocation = Math::Lerp(FVector::ForwardVector * -Distance * 0.5, FVector::ForwardVector * Distance * 0.5, Alpha);

	//	Debug::DrawDebugShape(CollisionShape, BoxComp.WorldLocation, BoxComp.WorldRotation, FLinearColor::Red, 10.0, 0.0);

		bool bHornClear = true;
		bool bCollisionClear = true;

		for (auto Player : Game::Players)
		{
			if (Shape::IsPointInside(HornShape, HornBox.WorldTransform, Player.ActorCenterLocation))
			{
				bHornClear = false;

				if (bShouldHorn)
					Horn();
			}

			if (Shape::IsPointInside(CollisionShape, BoxComp.WorldTransform, Player.ActorCenterLocation))
			{
				bCollisionClear = false;

				if (PlayerSlideComp[Player].IsSlideActive())
				{
					ActionCameraTimeStamp = Time::GameTimeSeconds;

					if (bPlayerDodgeEvent)
						PlayerDodge();

					if (!bForcedSliding[Player])
					{
						FSlideParameters SlideParams;
//						Player.StartTemporaryPlayerSlide(this, SlideParams);
						PlayerSlideComp[Player].StartTemporarySlide(this, SlideParams);
						bForcedSliding[Player] = true;

						// CameraSetting
						//Player.ApplyCameraSettings(SlideCameraSetting, 1.0, this, EHazeCameraPriority::VeryHigh);
					}
					
					continue;
				}

				if (PlayerWallRunComp[Player].HasActiveWallRun())
				{
					ActionCameraTimeStamp = Time::GameTimeSeconds;

					if (bPlayerDodgeEvent)
						PlayerDodge();

					if (!bInWallRun[Player])
					{
						bInWallRun[Player] = true;

						// CameraSetting
						//Player.ApplyCameraSettings(WallRunCameraSetting, 1.0, this, EHazeCameraPriority::VeryHigh);
					}

					continue;
				}

				if (PlayerGrappleComp[Player].IsGrappleActive())
				{
					ActionCameraTimeStamp = Time::GameTimeSeconds;

					if (bPlayerDodgeEvent)
						PlayerDodge();					

					continue;
				}

				if (TrainPivot.WorldTransform.InverseTransformPositionNoScale(Player.ActorLocation).X > 0.0 || TrainPivot.WorldTransform.InverseTransformPositionNoScale(Player.ActorLocation).Z < -300.0)
				{
					Player.ActivateCamera(DeathCamera, 0, this, EHazeCameraPriority::Cutscene);
					Player.KillPlayer(FPlayerDeathDamageParams(), DeathEffect);
					bKilledByTrain[Player] = true;
				}
				else
				{
					FVector KnockBackDirection = (TrainPivot.RightVector * TrainPivot.WorldTransform.InverseTransformPositionNoScale(Player.ActorLocation).Y).SafeNormal;
					Player.ApplyKnockdown((KnockBackDirection + FVector::UpVector) * 1000.0, 2.0);
					Player.DamagePlayerHealth(0.1);
				}
			}
			else 
			{
				if (bForcedSliding[Player])
				{
					PlayerSlideComp[Player].StopSlide(this);
					bForcedSliding[Player] = false;

					// CameraSetting
					Player.DeactivateCamera(SlideCamera, 1.0);
				}
			
				if (bInWallRun[Player])
				{
					bInWallRun[Player] = false;

					// CameraSetting
					Player.DeactivateCamera(WallRunCamera, 1.0);
				}
			}
			
			if(Time::GameTimeSeconds > ActionCameraTimeStamp + 3.0)
			{
				Player.DeactivateCamera(SlideCamera, 1.0);
				Player.DeactivateCamera(WallRunCamera, 1.0);
			}

			if(bKilledByTrain[Player] && !Player.IsPlayerDead())
			{
				Player.DeactivateCamera(DeathCamera);		
				bKilledByTrain[Player] = false;
				Player.SnapCameraBehindPlayer();
			}
		}

		if (!bShouldHorn && bHornClear)
			bShouldHorn = true;

		if (!bPlayerDodgeEvent && bCollisionClear)
			bPlayerDodgeEvent = true;
	
		DoProximityRumble(DeltaSeconds);
	}

	void Horn()
	{
//		PrintToScreen("HORN!", 4.0, FLinearColor::DPink);

		bShouldHorn = false;
		OnHorn.Broadcast();
		BP_Horn();
	}

	void PlayerDodge()
	{
//		PrintToScreen("PlayerDodge!", 4.0, FLinearColor::DPink);

		bPlayerDodgeEvent = false;
		OnPlayerDodge.Broadcast();
		BP_PlayerDodge();
	}

	void DoProximityRumble(float DeltaTime)
	{
		FVector LineStart = RumbleZone.WorldLocation + RumbleZone.UpVector * (RumbleZone.CapsuleHalfHeight - RumbleZone.CapsuleRadius);
		FVector LineEnd = RumbleZone.WorldLocation - RumbleZone.UpVector * (RumbleZone.CapsuleHalfHeight - RumbleZone.CapsuleRadius);
		float Inflate = 0.0;
		float InnerRadius = 500.0;
		float OuterRadius = RumbleZone.CapsuleRadius + Inflate;

//		Debug::DrawDebugLine(LineStart, LineEnd, FLinearColor::Green, 40.0);

		for (auto Player : Game::Players)
		{
			FVector PlayerLocation = Player.ActorCenterLocation;
			FVector ClosestPointOnLine = Math::ClosestPointOnLine(LineStart, LineEnd, PlayerLocation);

			float DistanceToPoint = PlayerLocation.Distance(ClosestPointOnLine);

			if (DistanceToPoint < OuterRadius)
			{
				float Alpha = Math::GetMappedRangeValueClamped(FVector2D(OuterRadius, InnerRadius), FVector2D(0.0, 1.0), DistanceToPoint);
//				Alpha *= Alpha;

//				PrintToScreen("RumbleAlpha: " + Alpha);
//				Debug::DrawDebugLine(ClosestPointOnLine, PlayerLocation, FLinearColor::Green, 20.0);
//				Debug::DrawDebugLine(ClosestPointOnLine, ClosestPointOnLine + (PlayerLocation - ClosestPointOnLine).SafeNormal * InnerRadius, FLinearColor::Red, 30.0);

				AccRumble[Player].SnapTo(Alpha);
			}
			else
			{
				AccRumble[Player].AccelerateTo(0.0, 2.0, DeltaTime);
			}

			FHazeFrameForceFeedback FFF;
			FFF.LeftMotor = AccRumble[Player].Value * 0.1;
			FFF.RightMotor = AccRumble[Player].Value * 0.2;

			Player.SetFrameForceFeedback(FFF);

			FHazeCameraImpulse CameraImpulse;
			CameraImpulse.CameraSpaceImpulse = Math::GetRandomPointInSphere() * 200.0 * AccRumble[Player].Value;
			CameraImpulse.ExpirationForce = 600.0;
			CameraImpulse.Dampening = 2.0;

			Player.ApplyCameraImpulse(CameraImpulse, this);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_Horn() { }

	UFUNCTION(BlueprintEvent)
	void BP_PlayerDodge() { }
};