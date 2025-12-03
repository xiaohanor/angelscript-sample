class ASkylineDiscoBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent ConeRotateComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UGravityWhipTargetComponent WhipTargetComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UGravityBladeCombatTargetComponent GravityBladeCombatTargetComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeCombatResponseComponent;

	float SwingVelocity;
	float TwistVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WhipResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		WhipResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
		GravityBladeCombatResponseComponent.OnHit.AddUFunction(this, n"HandleHit");
		SwingVelocity = ConeRotateComp.AngularVelocity.Size();;
		TwistVelocity = RotateComp.Velocity;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SwingVelocity = ConeRotateComp.AngularVelocity.Size();
		SwingVelocity *= 0.5;
		SwingVelocity = Math::Clamp(SwingVelocity,0,1);

		TwistVelocity = RotateComp.Velocity * 0.2;
		TwistVelocity = Math::Clamp(TwistVelocity,0,1);
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		FVector ImpulseForce = (WhipTargetComp.WorldLocation - Game::Mio.ActorCenterLocation).GetSafeNormal() * 800.0;
		ConeRotateComp.ApplyImpulse(WhipTargetComp.WorldLocation, ImpulseForce);
		RotateComp.ApplyAngularImpulse(ImpulseForce.Size() / 100.0);

		if (!WhipResponseComp.IsGrabbed())
			SetActorControlSide(Game::Mio);

		USkylineDiscoBallEventHandler::Trigger_HitByKatana(this);
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent,
	                           UGravityWhipTargetComponent TargetComponent,
	                           TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		ConeRotateComp.Friction = 10.0;
		SetActorControlSide(Game::Zoe);

		USkylineDiscoBallEventHandler::Trigger_GravityWhipGrabbed(this);
	}
	
	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent,
	                            UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		ConeRotateComp.Friction = 2.4;
		FVector ImpulseForce = ((ActorLocation - FVector::UpVector * 400.0) - WhipTargetComp.WorldLocation) * 2.0;
		ConeRotateComp.ApplyImpulse(WhipTargetComp.WorldLocation, ImpulseForce);
		RotateComp.ApplyAngularImpulse(ImpulseForce.Size() / 100.0);

		USkylineDiscoBallEventHandler::Trigger_GravityWhipReleased(this);
	}
};