event void FSkylineCarChaseTriggerSignature(ASkylineFlyingCar FlyingCar);

class ASkylineCarChaseTrigger : AActorAlignedToSpline
{
	UPROPERTY(DefaultComponent)
	UBoxComponent Trigger;

	UPROPERTY()
	FSkylineCarChaseTriggerSignature OnFlyingCarEntered;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto FlyingCar = Cast<ASkylineFlyingCar>(OtherActor);
		if (FlyingCar == nullptr)
			return;

		OnFlyingCarEntered.Broadcast(FlyingCar);
	}
}