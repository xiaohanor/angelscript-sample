event void FOnPinballGateOpen(APinballGate Gate);

UCLASS(Abstract)
class APinballGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeftRotatingRootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RightRotatingRootComp;

	UPROPERTY(DefaultComponent, Attach = LeftRotatingRootComp)
	UStaticMeshComponent LeftDoorMeshComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent CollisionComp;

	UPROPERTY()
	FOnPinballGateOpen OnPinballGateOpen;

	bool bOpen = false;
	TArray<APinballBreakableLock> Locks;

	UFUNCTION(BlueprintCallable)
	void OpenGate()
	{
		bOpen = true;
		CollisionComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		OnPinballGateOpen.Broadcast(this);
		UPinballGateEventHandler::Trigger_OnOpen(this);
		BP_OnGateOpened();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnGateOpened() {}

	void RegisterLock(APinballBreakableLock Lock)
	{
		if(Locks.Contains(Lock))
			return;

		Locks.Add(Lock);
		Lock.OnLockBroken.AddUFunction(this, n"OnLockBroken");
	}

	UFUNCTION()
	private void OnLockBroken(APinballBreakableLock Lock)
	{
		Locks.RemoveSingleSwap(Lock);

		FPinballGateOnLockBrokenEventData EventData;
		EventData.BreakableLock = Lock;
		UPinballGateEventHandler::Trigger_OnLockBroken(this, EventData);

		if(bOpen)
			return;

		if(Locks.IsEmpty())
			OpenGate();
	}
}