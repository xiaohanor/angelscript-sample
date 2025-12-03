
class UIslandOverseerFxCapability : UHazeCapability
{
	AIslandOverseerRoller Roller;
	UIslandOverseerRollerComponent RollerComp;
	FVector PreviousLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Roller = Cast<AIslandOverseerRoller>(Owner);
		RollerComp = UIslandOverseerRollerComponent::GetOrCreate(Owner);

		DisableFx(Roller.UpFxContainer);
		DisableFx(Roller.DownFxContainer);
		DisableFx(Roller.LeftFxContainer);
		DisableFx(Roller.RightFxContainer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!RollerComp.bSpinning)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!RollerComp.bSpinning)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PreviousLocation = Roller.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DisableFx(Roller.UpFxContainer);
		DisableFx(Roller.DownFxContainer);
		DisableFx(Roller.LeftFxContainer);
		DisableFx(Roller.RightFxContainer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Roller.ActorLocation == PreviousLocation)
			return;

		FVector Direction = (PreviousLocation - Roller.ActorLocation).GetSafeNormal();
		PreviousLocation = Roller.ActorLocation;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.UseLine();

		float TraceDistance = 500;
		auto RightHit = Trace.QueryTraceSingle(Owner.ActorLocation, Owner.ActorLocation + Owner.ActorRightVector * TraceDistance);
		auto LeftHit = Trace.QueryTraceSingle(Owner.ActorLocation, Owner.ActorLocation + -Owner.ActorRightVector * TraceDistance);
		auto UpHit = Trace.QueryTraceSingle(Owner.ActorLocation, Owner.ActorLocation + Owner.ActorUpVector * TraceDistance);
		auto DownHit = Trace.QueryTraceSingle(Owner.ActorLocation, Owner.ActorLocation + -Owner.ActorUpVector * TraceDistance);

		ToggleFx(Roller.UpFxContainer, UpHit.bBlockingHit);
		ToggleFx(Roller.DownFxContainer, DownHit.bBlockingHit);
		ToggleFx(Roller.LeftFxContainer, LeftHit.bBlockingHit);
		ToggleFx(Roller.RightFxContainer, RightHit.bBlockingHit);

		// Roller.UpFxContainer.WorldRotation = Direction.Rotation();
		// Roller.DownFxContainer.WorldRotation = Direction.Rotation();
		// Roller.LeftFxContainer.WorldRotation = Direction.Rotation();
		// Roller.RightFxContainer.WorldRotation = Direction.Rotation();
	}

	void ToggleFx(USceneComponent Container, bool bEnable)
	{
		if(bEnable)
			EnableFx(Container);
		else
			DisableFx(Container);
	}

	void EnableFx(USceneComponent Container)
	{
		TArray<UNiagaraComponent> Effects;
		Container.GetChildrenComponentsByClass(UNiagaraComponent, false, Effects);
		for(UNiagaraComponent Effect : Effects)
		{
			Effect.bAutoActivate = false;
			Effect.Activate();
		}
	}

	void DisableFx(USceneComponent Container)
	{
		TArray<UNiagaraComponent> Effects;
		Container.GetChildrenComponentsByClass(UNiagaraComponent, false, Effects);
		for(UNiagaraComponent Effect : Effects)
		{
			Effect.bAutoActivate = false;
			Effect.Deactivate();
		}
	}
}