event void FPlayerWeightActive();
event void FPlayerWeightNotActive();

class AMeltdownScreenWalkMioButtonActor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.SpringStrength = 10.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent Button;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent MioResponse;

	FPlayerWeightActive PlayerWeightActive;

	FPlayerWeightNotActive PlayerWeightNotActive;

	UPROPERTY(EditAnywhere)
	FVector Impulse;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MioResponse.OnAffected.AddUFunction(this,n"IsAffected");
		MioResponse.OnUnaffected.AddUFunction(this, n"IsUnaffected");
	}

	UFUNCTION()
	private void IsAffected()
	{
		PlayerWeightActive.Broadcast();
		IsAffectedEvent();
	}

	
	UFUNCTION()
	private void IsUnaffected()
	{
		PlayerWeightNotActive.Broadcast();
		IsNotAffectedEvent();
	}

	UFUNCTION(BlueprintEvent)
	private void IsAffectedEvent()
	{

	}

	UFUNCTION(BlueprintEvent)
	private void IsNotAffectedEvent()
	{
		
	}

};