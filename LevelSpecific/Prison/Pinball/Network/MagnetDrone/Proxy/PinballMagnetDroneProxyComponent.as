UCLASS(Abstract)
class UPinballMagnetDroneProxyComponent : UPinballProxyComponent
{
	APinballMagnetDroneProxy Proxy;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		Proxy = Cast<APinballMagnetDroneProxy>(Owner);

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballMagnetDroneProxy");
#endif
	}
};