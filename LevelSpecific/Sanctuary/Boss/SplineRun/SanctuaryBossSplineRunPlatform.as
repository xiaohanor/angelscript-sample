class ASanctuaryBossSplineRunPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateCompZ;
	default TranslateCompZ.bConstrainX = true;
	default TranslateCompZ.bConstrainY = true;
	default TranslateCompZ.SpringStrength = 20.0;

	UPROPERTY(DefaultComponent, Attach = TranslateCompZ)
	UFauxPhysicsConeRotateComponent ConeRotateComp;
	default ConeRotateComp.LocalConeDirection = -FVector::UpVector;
	default ConeRotateComp.Friction = 5.0;
	default ConeRotateComp.bConstrainTwist = true;
	default ConeRotateComp.SpringStrength = 0.2;

	UPROPERTY(DefaultComponent, Attach = FloatingComp)
	UStaticMeshComponent Platform1;
/*
	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UFauxPhysicsWeightComponent WeightComp;
	default WeightComp.RelativeLocation = FVector::UpVector * -400.0;
	default	WeightComp.MassScale = 0.2;
*/
	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	USanctuaryFloatingSceneComponent FloatingComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;
	default PlayerWeightComp.PlayerForce = 200.0;
	default PlayerWeightComp.PlayerImpulseScale = 0.05;

	UPROPERTY(EditAnywhere)
	AHazeTargetPoint TargetPoint;

	UPROPERTY(EditAnywhere)
	bool bShouldSwitch = false;

	UPROPERTY(EditAnywhere)
	bool bNoDecal = false;

	UPROPERTY(EditAnywhere)
	bool bStartActivated = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		if (!bStartActivated)
		{
			Platform1.SetHiddenInGame(true);
			Platform1.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
			
		
		if(TargetPoint == nullptr)
			return;
	}



	UFUNCTION()
	void ShouldSwitch()
	{
		bShouldSwitch = true;
	}


	void ShouldActivate()
	{	
		
		Platform1.SetHiddenInGame(false);
		Platform1.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	
		if(GetDistanceTo(TargetPoint) < 1500 && bShouldSwitch && bStartActivated)
			this.AddActorDisable(this);

		if(GetDistanceTo(TargetPoint) < 1500 && !bStartActivated && bShouldSwitch )
			ShouldActivate();
		
	}
};