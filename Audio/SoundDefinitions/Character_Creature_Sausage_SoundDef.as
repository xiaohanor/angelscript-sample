
UCLASS(Abstract)
class UCharacter_Creature_Sausage_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnGrillEvent(FPigWorldSausageParams Params){}

	UFUNCTION(BlueprintEvent)
	void OffGrillEvent(FPigWorldSausageParams Params){}

	UFUNCTION(BlueprintEvent)
	void HotDogReadyEvent(FPigWorldSausageParams Params){}

	UFUNCTION(BlueprintEvent)
	void StartSmokeEvent(FPigWorldSausageParams Params){}

	UFUNCTION(BlueprintEvent)
	void StopSmokeEvent(){}

	UFUNCTION(BlueprintEvent)
	void StartFireEvent(FPigWorldSausageParams Params){}

	UFUNCTION(BlueprintEvent)
	void StopFireEvent(){}

	UFUNCTION(BlueprintEvent)
	void ExplosionEvent(FPigWorldSausageParams Params){}

	UFUNCTION(BlueprintEvent)
	void Event(){}

	UFUNCTION(BlueprintEvent)
	void JumpEvent(){}

	UFUNCTION(BlueprintEvent)
	void LandEvent(){}

	UFUNCTION(BlueprintEvent)
	void FlopEvent(){}

	UFUNCTION(BlueprintEvent)
	void StartRollingEvent(){}

	UFUNCTION(BlueprintEvent)
	void StopRollingEvent(){}

	/* END OF AUTO-GENERATED CODE */
	
	APigWorldGrill InternalGrillPtr;

	UFUNCTION()
	void SubscribeToGrill(APigWorldGrill GrillActor)
	{
		InternalGrillPtr = GrillActor;

		GrillActor.GrillOverlapComp.OnComponentBeginOverlap.AddUFunction(this, n"OnGrillOverlapStart");
		GrillActor.GrillOverlapComp.OnComponentEndOverlap.AddUFunction(this, n"OnGrillOverlapEnd");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Will probably never be deactivated due to be attached to the players, but never hurts to be safe c:
		if (InternalGrillPtr != nullptr)
		{
			InternalGrillPtr.GrillOverlapComp.OnComponentBeginOverlap.UnbindObject(this);
			InternalGrillPtr.GrillOverlapComp.OnComponentEndOverlap.UnbindObject(this);
		}

		InternalGrillPtr = nullptr;
	}

	UFUNCTION()
	private void OnGrillOverlapStart(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                            const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (OtherActor == HazeOwner)
		{
			OnPlayerGrilledStart();
		}
	}

	UFUNCTION()
	private void OnGrillOverlapEnd(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                               UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (OtherActor == HazeOwner)
		{
			OnPlayerGrilledEnd();
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnPlayerGrilledStart() {}

	UFUNCTION(BlueprintEvent)
	void OnPlayerGrilledEnd() {}
}