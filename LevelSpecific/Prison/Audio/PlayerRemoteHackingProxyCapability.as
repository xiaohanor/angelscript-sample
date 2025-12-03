class UPlayerRemoteHackingProxyCapability : UHazePlayerCapability
{
	UPROPERTY(EditDefaultsOnly)
	TMap<ERemoteHackingDeviceSize, UHazeAudioAuxBus> DeviceVOBusses;

	private URemoteHackingPlayerComponent HackingComp;
	private UPlayerSwarmDroneHijackComponent HijackComp;
	private UPlayerMovementAudioComponent MoveAudioComp;
	bool bProxyActive = false;

	bool IsHacking() const
	{
		if(HackingComp != nullptr)
			return HackingComp.bHackActive;

		else if(HijackComp != nullptr)
			return HijackComp.IsHijackActive();

		return false;
	}

	URemoteHackingResponseAudioComponent GetAudioResponseComp() const
	{
		if(HackingComp != nullptr && HackingComp.CurrentHackingResponseComp != nullptr)
			return URemoteHackingResponseAudioComponent::Get(HackingComp.CurrentHackingResponseComp.Owner);
		else if(HijackComp != nullptr && HijackComp.CurrentHijackTargetable != nullptr)
			return URemoteHackingResponseAudioComponent::Get(HijackComp.CurrentHijackTargetable.Owner);

		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HackingComp = URemoteHackingPlayerComponent::Get(Player);	
		HijackComp = UPlayerSwarmDroneHijackComponent::Get(Player);
		MoveAudioComp = UPlayerMovementAudioComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerRemoteHackingProxyCapabilityActivationParams& ActivationParams) const
	{
		if(!IsHacking())
			return false;

		URemoteHackingResponseAudioComponent ResponseAudio = GetAudioResponseComp();
		if(ResponseAudio == nullptr)
			return false;

		if(ResponseAudio.DeviceSize == ERemoteHackingDeviceSize::None)
			return false;

		ActivationParams.ResponseAudioComp = ResponseAudio;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(IsHacking())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerRemoteHackingProxyCapabilityActivationParams ActivationParams)
	{
		UHazeAudioAuxBus VOProxyBus = nullptr;
		if(!DeviceVOBusses.Find(ActivationParams.ResponseAudioComp.DeviceSize, VOProxyBus))
			return;

		auto VOEmitter = Audio::GetPlayerVoEmitter(Player);

		FHazeProxyEmitterRequest Request;
		Request.AuxBus = VOProxyBus;
		Request.Instigator = FInstigator(this, n"RemoteHackingProxy");
		Request.InterpolationTime = ActivationParams.ResponseAudioComp.ProxyInterpolationTime;
		Request.Priority = 4;
		Request.Target = VOEmitter;
		Request.bSpatialized = false;
		Request.OnProxyRequest.BindUFunction(this, n"OnProxyRequest");

		bProxyActive = true;
		VOEmitter.RequestAuxSendProxy(Request);	

		MoveAudioComp.RequestBlockDefaultPlayerMovement(FInstigator(this));
		MoveAudioComp.RequestBlockMovement(this, EMovementAudioFlags::Breathing);
		MoveAudioComp.RequestBlockMovement(this, EMovementAudioFlags::Efforts);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bProxyActive = false;

		MoveAudioComp.UnRequestBlockDefaultPlayerMovement(FInstigator(this));
		MoveAudioComp.RequestUnBlockMovement(this, EMovementAudioFlags::Breathing);
		MoveAudioComp.RequestUnBlockMovement(this, EMovementAudioFlags::Efforts);
	}

	UFUNCTION()
	bool OnProxyRequest(UObject EmitterOwner, FName EmitterName, float32& outInterpolationTime)
	{
		return bProxyActive;
	}
}

struct FPlayerRemoteHackingProxyCapabilityActivationParams
{	
	UPROPERTY()
	URemoteHackingResponseAudioComponent ResponseAudioComp;	
}	