class UMonkeyCongaSetupAudioCapability : UHazePlayerCapability
{
	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference DefaultShapeshiftSoundDef;

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference MonkeyCongaShapeshiftSoundDef;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioAuxBus ProxyBus = nullptr;

	FHazeProxyEmitterRequest ProxyRequest;
	default ProxyRequest.bRequiresAuxEmitter = true;

	AHazeActor GetShapeshiftActor() const property
	{	
		if(Player.IsMio())
		{
			auto SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
			return SnowMonkeyComp.SnowMonkeyActor;
		}
		else
		{
			auto TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
			return TreeGuardianComp.TreeGuardianActor;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto PlayerShapeshiftActor = ShapeshiftActor;

		PlayerShapeshiftActor.RemoveSoundDef(DefaultShapeshiftSoundDef);		
		MonkeyCongaShapeshiftSoundDef.SpawnSoundDefAttached(PlayerShapeshiftActor);

		ProxyRequest.AuxBus = ProxyBus;
		ProxyRequest.Instigator = FInstigator(this);
		ProxyRequest.Priority = 1;
		ProxyRequest.Target = Player;
		ProxyRequest.OnProxyRequest.BindUFunction(this, n"OnProxyRequest");

		Player.RequestAuxSendProxy(ProxyRequest);
	}

	UFUNCTION()
	bool OnProxyRequest(UObject ProxyOwner, FName EmitterName, float32& InterpolationTime)
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto PlayerShapeshiftActor = ShapeshiftActor;
		// Re-add SDs
		DefaultShapeshiftSoundDef.SpawnSoundDefAttached(PlayerShapeshiftActor);	
		MonkeyCongaShapeshiftSoundDef.RemoveFromActor(PlayerShapeshiftActor);
	}
}