event void FOonButtonJumped();

class AMeltdownScreenWalkButtonActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.SpringStrength = 10.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent Button;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	FOonButtonJumped JumpedOn;

	UPROPERTY(EditAnywhere)
	FVector Impulse;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnJumpTrigger.AddUFunction(this, n"OnActivated");

	}

	UFUNCTION()
	private void OnActivated()
	{
		OnJumped();
		JumpedOn.Broadcast();
		TranslateComp.ApplyImpulse(
		ActorLocation, FVector(Impulse)
		);
	}

	UFUNCTION(BlueprintEvent)
	void OnJumped()
	{

	}
};