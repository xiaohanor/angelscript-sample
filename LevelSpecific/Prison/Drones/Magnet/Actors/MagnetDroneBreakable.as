class AMagnetDroneBreakable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = RootComp)
	UStaticMeshComponent RailFrontComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent Direction;

	bool bSmashed = false;

	UPROPERTY(DefaultComponent)
	UMagnetDroneImpactResponseComponent ImpactResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		ImpactResponseComp.OnImpact.AddUFunction(this, n"OnImpact");
	}

	UFUNCTION()
	private void OnImpact(FMagnetDroneOnImpactData Data)
	{
		if (!HasControl())
			return;
	
		if(bSmashed)
			return;

		CrumbOnMagnetDroneHit();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnMagnetDroneHit()
	{
		if(bSmashed)
			return;
		
		UMagnetDroneBreakableEventHandler::Trigger_Break(this);
		Break();
	}

	UFUNCTION(BlueprintEvent)
	void Break() 
	{
		bSmashed = true;
		//this.AddActorDisable(this);
		RailFrontComp.SetHiddenInGame(true);
		RailFrontComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		Timer::SetTimer(this,n"Launch",0.01f,false,0,0);
	}

	UFUNCTION()
	private void Launch()
	{
		FVector LaunchDirection = Direction.GetForwardVector()*1000;
		LaunchDirection.Z = 1000;

		Game::Zoe.AddMovementImpulse(LaunchDirection);
	}
}