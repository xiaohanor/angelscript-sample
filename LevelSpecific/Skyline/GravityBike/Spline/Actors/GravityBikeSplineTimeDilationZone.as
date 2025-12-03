UCLASS(Abstract)
class AGravityBikeSplineTimeDilationZone : AHazeActor
{
	private FTimeDilationEffect TimeDilationEffect;
	private bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		auto Box = GetBoxComponent();
		TimeDilationEffect = GetTimeDilationEffect();

		if(HasControl())
		{
			Box.OnComponentBeginOverlap.AddUFunction(this, n"OnEnter");
			Box.OnComponentEndOverlap.AddUFunction(this, n"OnExit");
		}
	}

	UFUNCTION()
	private void OnEnter(
		UPrimitiveComponent OverlappedComponent,
		AActor OtherActor,
	    UPrimitiveComponent OtherComp,
		int OtherBodyIndex,
		bool bFromSweep,
	    const FHitResult&in SweepResult)
	{
		check(HasControl());

		if(bActive)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if(!Player.IsMio())
			return;

		CrumbActivate();
	}

	UFUNCTION()
	private void OnExit(
		UPrimitiveComponent OverlappedComponent,
		AActor OtherActor,
	    UPrimitiveComponent OtherComp,
		int OtherBodyIndex)
	{
		check(HasControl());

		if(!bActive)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if(!Player.IsMio())
			return;

		CrumbDeactivate();
	}

	UFUNCTION(BlueprintCallable)
	void BP_Activate()
	{
		if(!HasControl())
			return;

		if(bActive)
			return;

		CrumbActivate();
	}

	UFUNCTION(BlueprintCallable)
	void BP_Deactivate()
	{
		if(!HasControl())
			return;

		if(!bActive)
			return;

		CrumbDeactivate();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivate()
	{
		TimeDilation::StartWorldTimeDilationEffect(TimeDilationEffect, this);

		bActive = true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDeactivate()
	{
		TimeDilation::StopWorldTimeDilationEffect(this);

		bActive = false;
	}

	UFUNCTION(BlueprintEvent)
	UBoxComponent GetBoxComponent() const { return nullptr; }

	UFUNCTION(BlueprintEvent)
	FTimeDilationEffect GetTimeDilationEffect() const { return FTimeDilationEffect(); }
};