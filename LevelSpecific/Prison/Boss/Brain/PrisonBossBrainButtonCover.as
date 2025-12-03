event void FPrisonBossBrainButtonCoverOpenedEvent();
event void FPrisonBossBrainButtonCoverClosedEvent(bool bAutomatic);

UCLASS(Abstract)
class APrisonBossBrainButtonCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CoverRoot;

	UPROPERTY(DefaultComponent, Attach = CoverRoot)
	UFauxPhysicsAxisRotateComponent TopLeftCoverRoot;

	UPROPERTY(DefaultComponent, Attach = CoverRoot)
	UFauxPhysicsAxisRotateComponent TopRightCoverRoot;

	UPROPERTY(DefaultComponent, Attach = CoverRoot)
	UFauxPhysicsAxisRotateComponent BottomLeftCoverRoot;

	UPROPERTY(DefaultComponent, Attach = CoverRoot)
	UFauxPhysicsAxisRotateComponent BottomRightCoverRoot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	TArray<UFauxPhysicsAxisRotateComponent> FauxPhysicsComps;

	UPROPERTY()
	FPrisonBossBrainButtonCoverOpenedEvent OnOpened;

	UPROPERTY()
	FPrisonBossBrainButtonCoverClosedEvent OnClosed;

	bool bOpen = false;

	float OriginalSpringStrength;

	float OpenDuration = 4.0;

	bool bGrappleInitiated = false;

	APrisonBoss BossActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(UFauxPhysicsAxisRotateComponent, FauxPhysicsComps);

		OriginalSpringStrength = TopRightCoverRoot.SpringStrength;

		BossActor = TListedActors<APrisonBoss>().Single;
	}

	UFUNCTION()
	void OpenCover(float Duration = 4.0)
	{
		if (bOpen)
			return;

		bOpen = true;
		BP_OpenCover();

		OnOpened.Broadcast();

		for (UFauxPhysicsAxisRotateComponent Comp : FauxPhysicsComps)
		{
			Comp.SpringStrength = 0.0;
		}

		Timer::SetTimer(this, n"CloseCoversAuto", Duration);

		BossActor.ButtonCoverOpened();

		UPrisonBossBrainButtonCoverEffectEventHandler::Trigger_OpenCover(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenCover() {}

	UFUNCTION()
	void SetGrappleInitiated(bool bInitiated)
	{
		bGrappleInitiated = bInitiated;
	}

	UFUNCTION()
	private void CloseCoversAuto()
	{
		CloseCovers(true);
	}

	UFUNCTION()
	void CloseCovers(bool bAutomatic)
	{
		if (!bOpen)
			return;

		if (bGrappleInitiated)
			return;

		bOpen = false;
		BP_CloseCover();

		OnClosed.Broadcast(bAutomatic);

		for (UFauxPhysicsAxisRotateComponent Comp : FauxPhysicsComps)
		{
			Comp.SpringStrength = OriginalSpringStrength;
		}

		UPrisonBossBrainButtonCoverEffectEventHandler::Trigger_CloseCover(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_CloseCover() {}

	UFUNCTION()
	void Blasted()
	{
		for (UFauxPhysicsAxisRotateComponent Comp : FauxPhysicsComps)
		{
			Comp.ApplyAngularImpulse(-8.0);
		}
		
		BP_Blasted();

		UPrisonBossBrainButtonCoverEffectEventHandler::Trigger_MagnetBlasted(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Blasted() {}

	UFUNCTION()
	void SetInactive()
	{
		BP_SetInactive();
	}

	UFUNCTION(BlueprintEvent)
	void BP_SetInactive() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bOpen)
		{
			for (UFauxPhysicsAxisRotateComponent Comp : FauxPhysicsComps)
			{
				Comp.ApplyAngularForce(-20.0);
			}

			CoverRoot.AddLocalRotation(FRotator(0.0, 0.0, 60.0 * DeltaTime));
		}
	}
}