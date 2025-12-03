class AIslandFloatingPerch : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovingRoot;
	
	UPROPERTY(DefaultComponent, Attach = MovingRoot)
	UFauxPhysicsTranslateComponent TranslateRoot;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	UFauxPhysicsConeRotateComponent ConeRotateRoot;

	UPROPERTY(DefaultComponent, Attach = ConeRotateRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	UPerchPointComponent PerchComp;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	UPerchEnterByZoneComponent PerchEnterByZoneComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	float AmbientMovementCounter = 0;
	
	UPROPERTY(EditInstanceOnly)
	float AmbientMovementAmplitude = 15;

	UPROPERTY(EditInstanceOnly)
	float AmbientMovementDuration = 5;

	float AmbientMovementOffset = 0;

	UPROPERTY(EditDefaultsOnly)
	float SinkSpeed = 50;

	bool bPlayerPerching = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerPerched");
		PerchComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStoppedPerching");

		AmbientMovementCounter = Math::RandRange(0.0, AmbientMovementDuration);
	}

	UFUNCTION()
	private void OnPlayerStoppedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		if(PerchComp.IsPlayerOnPerchPoint[Player.OtherPlayer])
		{
			bPlayerPerching = true;
		}
		else
		{
			bPlayerPerching = false;
		}
	}

	UFUNCTION()
	private void OnPlayerPerched(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		bPlayerPerching = true;

		TranslateRoot.ApplyImpulse(TranslateRoot.WorldLocation, -FVector::UpVector * 300.0);
		ConeRotateRoot.ApplyImpulse(ConeRotateRoot.WorldLocation + FVector::UpVector * 50, Player.ActorForwardVector * 30);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// if(bPlayerPerching)
		// {
		// 	TranslateRoot.ApplyForce(TranslateRoot.WorldLocation + (FVector::UpVector * 20.0), -FVector::UpVector * SinkSpeed);
		// }
		// else
		// {
		AmbientMovementCounter += DeltaSeconds;
		if(AmbientMovementCounter > AmbientMovementDuration)
		{
			AmbientMovementCounter -= AmbientMovementDuration;
		}

		float SinMove = Math::Sin((AmbientMovementCounter/AmbientMovementDuration)*PI*2)*AmbientMovementAmplitude * 1.5;
		MovingRoot.SetRelativeLocation(FVector(MovingRoot.RelativeLocation.X,MovingRoot.RelativeLocation.Y,SinMove));
		// }
	}
};