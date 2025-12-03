class AMovingVine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedAlpha;
	default SyncedAlpha.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(EditAnywhere)
	APoleClimbActor PoleRef;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineRef;

	UPROPERTY(EditAnywhere)
	AEvergreenLifeManager Manager;	

	UPROPERTY(EditAnywhere)
	bool bHorizontal = true;
	
	UPROPERTY(EditAnywhere)
	bool bAllowMovement = true;

	UPROPERTY(EditAnywhere)
	float Speed = 450;

	UPROPERTY(EditAnywhere)
	bool bFlipped = false;

	UPROPERTY(EditAnywhere)
	bool bResetPositionOnPlayerKilled = false;

	UPROPERTY(EditAnywhere)
	bool bStartAtEnd = false;

	UPROPERTY(EditAnywhere)
	bool bUseEvergreenSideSmoothing = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPlayerHealthComponent MioHealthComp;

	FHazeAcceleratedVector AccVector;

	UPROPERTY(EditAnywhere)
	ADynamicWaterEffectDecal WaterDecalLeft;

	UPROPERTY(EditAnywhere)
	ADynamicWaterEffectDecal WaterDecalRight;

	UPROPERTY(EditAnywhere)
	ADynamicWaterEffectDecal WaterDecalMoveNoise;

	UPROPERTY(DefaultComponent)
	UHazeRawVelocityTrackerComponent RawVelocityComp;

	UPROPERTY(EditInstanceOnly)
	TSubclassOf<UCameraShakeBase> CamshakeMio;

	UPROPERTY(EditInstanceOnly)
	FHazeFrameForceFeedback MioFFWhenWallMoves;

	UCameraShakeBase CamShake;

	float StartSplineDistance = 0;
	float SplineDistance = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		StartSplineDistance = SplineRef.Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation);
		SplineDistance = StartSplineDistance;
		SyncedAlpha.Value = SplineDistance / SplineRef.Spline.SplineLength;

		AccVector.SnapTo(ActorLocation);

		MioHealthComp = UPlayerHealthComponent::Get(Game::GetMio());

		if(HasControl())
			MioHealthComp.OnStartDying.AddUFunction(this, n"MioDied");

		ActorLocationPrev = ActorLocation;
	}

	UFUNCTION()
	void MioDied()
	{
		if(bResetPositionOnPlayerKilled)
			ResetPosition();
	}

	UFUNCTION()
	void ResetPosition()
	{
		bAllowMovement = false;
		SplineDistance = StartSplineDistance;
		SyncedAlpha.Value = SplineDistance / SplineRef.Spline.SplineLength;
		SyncedAlpha.SnapRemote();
	}

	FVector ActorLocationPrev;
	float smoothSpeed;

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(CamShake == nullptr)
			return;

		Game::GetMio().StopCameraShakeByInstigator(this);
		CamShake = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		if(CamShake == nullptr)
			return;

		Game::GetMio().StopCameraShakeByInstigator(this);
		CamShake = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl() && bAllowMovement)
		{
			float Input = bHorizontal ? Manager.LifeComp.RawHorizontalInput : Manager.LifeComp.RawVerticalInput * -1;
			
			SplineDistance += Speed * DeltaSeconds * Input;
			SplineDistance = Math::Clamp(SplineDistance, 0, SplineRef.Spline.SplineLength);
			
			float AlphaTarget = SplineDistance / SplineRef.Spline.SplineLength;
			SyncedAlpha.Value = AlphaTarget;
		}

		if(!HasControl())
			SplineDistance = SplineRef.Spline.SplineLength * SyncedAlpha.Value;

		//Per shenanigans start
		FVector Target = SplineRef.Spline.GetWorldLocationAtSplineDistance(SplineDistance);
		if(bUseEvergreenSideSmoothing)
		{
			ActorLocation = AccVector.AccelerateTo(Target, 1, DeltaSeconds);
		}
		else
		{
			ActorLocation = Target;
		}

		float RawVelocity = GetRawLastFrameTranslationVelocity().Size();

		if (RawVelocity >= 60)
		{
			ForceFeedback::PlayWorldForceFeedbackForFrame(MioFFWhenWallMoves, ActorLocation, 600, 2000, 1, EHazeSelectPlayer::Mio, false);
			
			if(CamshakeMio != nullptr)
			{
				if(CamShake == nullptr)
				{
					CamShake = Game::GetMio().PlayCameraShake(CamshakeMio, this, 1);
				}
				
				CamShake.ShakeScale = CalcRadialShakeScale(ActorLocation, 150, 3000, 1) * 0.5;
				// PrintToScreen(""+CamShake.ShakeScale, 0);
			}
		}
		else if(CamShake != nullptr)
		{
			Game::GetMio().StopCameraShakeByInstigator(this);
			CamShake = nullptr;
		}
		//Per shenanigans stop

		

		FVector Delta = ActorLocation - ActorLocationPrev;
		ActorLocationPrev = ActorLocation;
		if(WaterDecalLeft != nullptr && WaterDecalRight != nullptr && WaterDecalMoveNoise != nullptr)
		{
			float speed = Delta.Y * 0.2;
			smoothSpeed = Math::FInterpTo(smoothSpeed, speed, DeltaSeconds, 1);
			WaterDecalLeft.DynamicWaterEffectDecalComponent.Strength = -smoothSpeed;
			WaterDecalRight.DynamicWaterEffectDecalComponent.Strength = smoothSpeed;
			WaterDecalMoveNoise.DynamicWaterEffectDecalComponent.Strength = smoothSpeed * 2.0;
		}
	}


	float CalcRadialShakeScale(FVector Epicenter, float InnerRadius, float OuterRadius, float Falloff)
	{
		// using camera location so stuff like spectator cameras get shakes applied sensibly as well
		// need to ensure server has reasonably accurate camera position
		FVector POVLoc = Game::GetMio().ActorLocation;

		if (InnerRadius < OuterRadius)
		{
			float DistPct = ((Epicenter - POVLoc).Size() - InnerRadius) / (OuterRadius - InnerRadius);
			DistPct = 1 - Math::Clamp(DistPct, 0, 1);
			return Math::Pow(DistPct, Falloff);
		}
		else
		{
			// ignore OuterRadius and do a cliff falloff at InnerRadius
			return ((Epicenter - POVLoc).SizeSquared() < Math::Square(InnerRadius)) ? 1 : 0;
		}
	}
}