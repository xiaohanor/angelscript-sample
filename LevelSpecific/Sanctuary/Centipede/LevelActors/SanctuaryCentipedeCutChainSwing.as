class ASanctuaryCentipedeCutChainSwing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCentipedeBiteResponseComponent BiteResponseComp1;

	UPROPERTY(DefaultComponent, Attach = BiteResponseComp1)
	UNiagaraComponent Bite1VFXComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCentipedeBiteResponseComponent BiteResponseComp2;

	UPROPERTY(DefaultComponent, Attach = BiteResponseComp2)
	UNiagaraComponent Bite2VFXComp;

	UPROPERTY(EditAnywhere)
	int BitesRequired = 5;

	int Bites1 = 0;
	int Bites2 = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BiteResponseComp1.OnCentipedeBiteStarted.AddUFunction(this, n"HandleBite1");
		BiteResponseComp2.OnCentipedeBiteStarted.AddUFunction(this, n"HandleBite2");
	}

	UFUNCTION()
	private void HandleBite1(FCentipedeBiteEventParams BiteParams)
	{
		Bites1++;
		Bite1VFXComp.Activate(true);

		if (Bites1 >= BitesRequired)
		{

		}
	}

	UFUNCTION()
	private void HandleBite2(FCentipedeBiteEventParams BiteParams)
	{
		Bites2++;
		Bite2VFXComp.Activate(true);

		if (Bites2 >= BitesRequired)
		{
			
		}
	}
};