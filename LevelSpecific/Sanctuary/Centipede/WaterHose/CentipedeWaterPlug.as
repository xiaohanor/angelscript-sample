event void FCentipedeWaterPlufUnplugged(AHazePlayerCharacter BitingPlayer);

UCLASS(Abstract)
class ACentipedeWaterPlug : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FauxRoot;

	UPROPERTY(DefaultComponent, Attach = FauxRoot)
	UFauxPhysicsSplineTranslateComponent SplineTranslateComp;
	default SplineTranslateComp.bStartDisabled = true;
	default SplineTranslateComp.bConstrainWithSpline = false;

	UPROPERTY(DefaultComponent, Attach = SplineTranslateComp)
	UFauxPhysicsFreeRotateComponent FauxFreeRotateComp;

	UPROPERTY(DefaultComponent, Attach = FauxFreeRotateComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent RingMesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent PlugMesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UCentipedeBiteResponseComponent BiteResponseComp;
	default BiteResponseComp.bAutoTargetWhileBitten = false;

	UPROPERTY(DefaultComponent, Attach = BiteResponseComp)
	UArrowComponent TargetTransformComp;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect UnpluggedForceFeedback;

	UPROPERTY(Category = "VFX", EditDefaultsOnly)
	UNiagaraSystem PlugDestroyedVFX;

	FCentipedeWaterPlufUnplugged OnUnplugged;

	const float LetGoDestructionTimer = 3.0;
	float TimeSinceLetGo = 0;

	bool bIsUnplugged = false;
	bool bIsDragged = false;

	bool bFauxing = false;

	bool bStoppedMoveIsh = false;
	bool bGettingDestroyed = false;

	AHazePlayerCharacter BitingPlayer;

	void Unplug()
	{
		if (HasControl() && !bIsUnplugged)
			CrumbUnplug();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbUnplug()
	{
		bIsUnplugged = true;
		OnUnplugged.Broadcast(BitingPlayer);
		UCentipedeWaterPlugEventHandler::Trigger_OnUnplug(this, GetEventData());
	}

	FCentipedeWaterPlugEventData GetEventData() const
	{
		FCentipedeWaterPlugEventData Data;
		Data.Player = BitingPlayer;
		return Data;
	}

	void LetGo()
	{
		UCentipedeWaterPlugEventHandler::Trigger_OnPlayerDetach(this, GetEventData());

		bFauxing = true;
		TimeSinceLetGo = 0.0;

		TListedActors<ACentipedeWaterPlugFauxBoundary> FauxBoundaries;
		SplineTranslateComp.OtherSplineActor = FauxBoundaries.Single;
		SplineTranslateComp.bConstrainWithSpline = true;
		SplineTranslateComp.bClockwise = false;
		SplineTranslateComp.RemoveDisabler(SplineTranslateComp);

		SplineTranslateComp.ApplyImpulse(ActorLocation, BitingPlayer.ActorVelocity * 3.0 + FVector::UpVector);
		FauxFreeRotateComp.ApplyImpulse(BitingPlayer.ActorLocation, BitingPlayer.ActorVelocity * 3.0  + FVector::UpVector);

		BiteResponseComp.Disable(this);
		Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		RingMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		PlugMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		BitingPlayer = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bFauxing && !bStoppedMoveIsh)
		{
			float VelocitySize = SplineTranslateComp.GetVelocity().Size();
			if (VelocitySize < 10.0 && TimeSinceLetGo > 0.3)
			{
				bStoppedMoveIsh = true;
				UCentipedeWaterPlugEventHandler::Trigger_OnIshStopMoving(this);
			}
		}

		if (SanctuaryCentipedeDevToggles::Draw::WaterPlug.IsEnabled())
		{
			ColorDebug::DrawTintedTransform(TargetTransformComp.WorldLocation, TargetTransformComp.WorldRotation, ColorDebug::White);
			if (BitingPlayer != nullptr)
				ColorDebug::DrawTintedTransform(TargetTransformComp.WorldLocation, TargetTransformComp.WorldRotation, BitingPlayer.GetPlayerUIColor());
		}

		if (bFauxing)
		{
			if (!bGettingDestroyed)
			{
				if (HasControl() && TimeSinceLetGo >= LetGoDestructionTimer)
					Crumb_Hide();
				else
					TimeSinceLetGo += DeltaSeconds;
			}

			/*
			if (HasControl())
			{
				for (FVector Location: GetBodyLocations())
				{
					if(PlugMesh.WorldLocation.IsWithinDist(Location, 110.0))
					{
						Crumb_Hide();
						break;
					}
				}
			}
			*/
		}
	}

	private TArray<FVector> GetBodyLocations() const
	{
		TArray<FVector> Locations;
		UPlayerCentipedeComponent CentipedeComp = UPlayerCentipedeComponent::Get(Game::Mio);
		if(ensure(CentipedeComp != nullptr, "Can only target centipede players!"))
			Locations = CentipedeComp.GetBodyLocations();
		return Locations;
	}

	UFUNCTION(CrumbFunction)
	private void Crumb_Hide()
	{
		if (bGettingDestroyed)
			return;

		if (PlugDestroyedVFX != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(PlugDestroyedVFX, PlugMesh.WorldLocation);

		UCentipedeWaterPlugEventHandler::Trigger_OnDestroyed(this);
		bGettingDestroyed = true;

		Mesh.SetHiddenInGame(true);
		this.SetAutoDestroyWhenFinished(true);
	}
};