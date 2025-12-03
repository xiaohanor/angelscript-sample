class ASandSharkTrapGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent LeftRopeAttach;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent RightRopeAttach;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> OpenShake;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CloseShake;

	UPROPERTY()
	UForceFeedbackEffect OpenFF;

	UPROPERTY()
	UForceFeedbackEffect CloseFF;

	FVector StartLocation;

	UPROPERTY(NotEditable, NotVisible, BlueprintReadOnly)
	bool bActive;

	bool bHit;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		TranslateComp.OnConstraintHit.AddUFunction(this, n"ConstraintHit");
	}

	UFUNCTION()
	private void ConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{		
		if(bHit)
			return;
		bHit = true;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(bActive)
			{
				Player.PlayForceFeedback(OpenFF, false, false, this);
				Player.PlayCameraShake(OpenShake, this);
				continue;
			}
			Player.PlayForceFeedback(CloseFF, false, false, this);
			Player.PlayCameraShake(CloseShake, this);
		}
	}

	UFUNCTION()
	void Activate()
	{
		bActive = true;
		bHit = false;
	}

	UFUNCTION()
	void Deactivate()
	{
		bActive = false;
		bHit = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bActive)
			return;

		TranslateComp.ApplyForce(ActorLocation, FVector::UpVector * 6000);
	}
}