class ASummitKnightHorse : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;	

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent LandFx;
	default LandFx.bAutoActivate = false;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	float CameraShakeMultiplier = 1.0;

	bool bStarted;
	bool bLanded;
	float TargetDistance;
	float Distance;
	float DelayTimer;

	UFUNCTION()
	void Start()
	{
		bStarted = true;
		TargetDistance = SplineActor.Spline.SplineLength;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bStarted)
			return;
		if(Distance > TargetDistance)
			return;

		if(Distance > 8500 && DelayTimer < 2)
		{
			if(!bLanded)
			{
				bLanded = true;
				LandFx.Activate();
				Game::Mio.PlayCameraShake(CameraShake, this, CameraShakeMultiplier);
				Game::Zoe.PlayCameraShake(CameraShake, this, CameraShakeMultiplier);
				for(AHazePlayerCharacter Player: Game::Players)
				{
					float PlayerDistance = Player.ActorLocation.Distance(ActorLocation);
					if(PlayerDistance < 3000)
					{						
						auto DragonComp = UPlayerTeenDragonComponent::Get(Player);
						if(DragonComp == nullptr)
							continue;

						FVector Dir = (Player.ActorLocation - ActorLocation).ConstrainToPlane(Player.ActorUpVector).GetSafeNormal2D();
						Dir.Z = 0.75;
						float Impulse = 1500 + (3000 - PlayerDistance);
						Player.AddMovementImpulse(Dir*Impulse);
					}
				}
			}
			DelayTimer += DeltaSeconds;
			return;
		}

		Distance += DeltaSeconds * 5000;
		ActorLocation = SplineActor.Spline.GetWorldLocationAtSplineDistance(Distance);
		FRotator Rot = SplineActor.Spline.GetWorldRotationAtSplineDistance(Distance).Rotator();
		ActorRotation = FRotator(Math::Max(Rot.Pitch, 0), Rot.Yaw, Rot.Roll);
	}
}