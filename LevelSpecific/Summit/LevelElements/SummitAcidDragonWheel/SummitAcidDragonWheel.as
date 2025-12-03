event void FONSpinning(float SpinSpeed);

class ASummitAcidDragonWheel : AHazeActor
{
	FONSpinning OnSpinning;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;


	float MaxSpinSpeed = 10.0;
	float SpinAcceleration = 15.0;
	float SpinDecceleration = 15.0;
	float SpinSpeed;
	float SpinDirection;
	
	bool bIsBeingHit;
	UPROPERTY(EditAnywhere)
	bool bDebugPrint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		OnSpinning.Broadcast(SpinSpeed);

		if(bDebugPrint)
			PrintToScreen("SpinSpeed: " + SpinSpeed);
		
		FRotator Rotation = FRotator(0.0, 0.0, SpinSpeed);
		MeshComp.AddRelativeRotation(Rotation);

		if(!bIsBeingHit)
			SpinSpeed = Math::FInterpConstantTo(SpinSpeed, 0.0, DeltaSeconds, SpinDecceleration);
		

		if(SpinDirection > 0)
			SpinSpeed = Math::Clamp(SpinSpeed, 0, MaxSpinSpeed);

		else if(SpinDirection < 0)
			SpinSpeed = Math::Clamp(SpinSpeed, -MaxSpinSpeed, 0);

		bIsBeingHit = false;
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		bIsBeingHit = true;


		SpinDirection =  ActorRightVector.DotProduct(-Hit.ImpactNormal);
		SpinSpeed += SpinAcceleration * SpinDirection;
		
	}
}