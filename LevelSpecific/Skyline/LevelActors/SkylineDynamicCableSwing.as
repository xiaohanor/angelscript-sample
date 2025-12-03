class ASkylineDynamicCableSwing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent ConeRotateComp;
	default ConeRotateComp.LocalConeDirection = -FVector::UpVector;
	default ConeRotateComp.ConeAngle = 180.0;
	default ConeRotateComp.Friction = 1.2;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	USceneComponent Pivot;
	default Pivot.RelativeLocation = -FVector::UpVector * 500.0;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.Force = -FVector::UpVector * 800.0;

	UPROPERTY(DefaultComponent, Attach = Root)
	USwingPointComponent SwingPointComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	float SwingForce = 1500.0;

	TArray<AHazePlayerCharacter> AttachedPlayers;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ConeRotateComp.AddDisabler(this);
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		SwingPointComp.SetWorldRotation(FRotator::ZeroRotator);
		SwingPointComp.Disable(this);

		SwingPointComp.OnPlayerAttachedEvent.AddUFunction(this, n"HandlePlayerAttached");
		SwingPointComp.OnPlayerDetachedEvent.AddUFunction(this, n"HandlePlayerDetached");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (AttachedPlayers.Num() > 0)
			ConeRotateComp.Friction = 2.4;
		else
			ConeRotateComp.Friction = 1.2;
			
		for (auto AttachedPlayer : AttachedPlayers)
		{
			FVector Force = (AttachedPlayer.ActorLocation - Pivot.WorldLocation).GetSafeNormal() * SwingForce;
			ConeRotateComp.ApplyForce(Pivot.WorldLocation, Force);

			UPlayerSwingComponent PlayerSwingComp = UPlayerSwingComponent::Get(AttachedPlayer);
			PlayerSwingComp.SetRopeAttachLocation(Pivot.WorldLocation);
		}	

		UpdateSwingWidgetOffset();
	}

	private void UpdateSwingWidgetOffset()
	{
		SwingPointComp.WidgetVisualOffset = Pivot.WorldLocation - SwingPointComp.WorldLocation;
	}


	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		ConeRotateComp.RemoveDisabler(this);
		SwingPointComp.Enable(this);
	}

	UFUNCTION()
	private void HandlePlayerAttached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		AttachedPlayers.Add(Player);
//		ForceComp.AddDisabler(Player);
	}

	UFUNCTION()
	private void HandlePlayerDetached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		AttachedPlayers.Remove(Player);
//		ForceComp.RemoveDisabler(Player);	
	}
};