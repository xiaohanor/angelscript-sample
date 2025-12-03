event void FCentipedeBodyTriggerBeginOverlapSignature(UActorComponent OverlappedComponent);
event void FCentipedeBodyTriggerEndOverlapSignature(UActorComponent OverlappedComponent);

class UCentipedeBodyTriggerResponseComponent : UActorComponent
{
	UPROPERTY(Category = "Response", Meta = (NotBlueprintCallable))
	FCentipedeBodyTriggerBeginOverlapSignature OnBodyBeginOverlap;

	UPROPERTY(Category = "Response", Meta = (NotBlueprintCallable))
	FCentipedeBodyTriggerEndOverlapSignature OnBodyEndOverlap;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void BodyBeginOverlap(UActorComponent OverlappedComponent)
	{
		OnBodyBeginOverlap.Broadcast(OverlappedComponent);
	}

	UFUNCTION()
	void BodyEndOverlap(UActorComponent OverlappedComponent)
	{
		OnBodyEndOverlap.Broadcast(OverlappedComponent);
	}
};