enum ERemoteHackingDeviceSize
{
	None,
	Small,
	Medium,
	Large
}

class URemoteHackingResponseAudioComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	ERemoteHackingDeviceSize DeviceSize = ERemoteHackingDeviceSize::None;

	UPROPERTY(EditAnywhere)
	float ProxyInterpolationTime = 0.1;
}