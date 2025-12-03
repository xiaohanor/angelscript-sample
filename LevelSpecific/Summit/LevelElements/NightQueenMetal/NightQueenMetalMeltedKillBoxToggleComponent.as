class UNightQueenMetalMeltedKillBoxToggleComponent : UActorComponent
{
	ANightQueenMetal MetalOwner;
	USummitDeathVolumeComponent DeathVolume;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto ActorOwner = GetOwner();
		MetalOwner = Cast<ANightQueenMetal>(ActorOwner);
		if(MetalOwner != nullptr)
		{
			MetalOwner.OnCollisionEnabled.AddUFunction(this, n"TurnOnDeathVolume");
			MetalOwner.OnCollisionDisabled.AddUFunction(this, n"TurnOffDeathVolume");
			auto ActorComponent = MetalOwner.GetComponentByClass(USummitDeathVolumeComponent);
			DeathVolume = Cast<USummitDeathVolumeComponent>(ActorComponent);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void TurnOnDeathVolume()
	{
		DeathVolume.SetKillActive(true);
	}

	UFUNCTION(NotBlueprintCallable)
	void TurnOffDeathVolume()
	{
		DeathVolume.SetKillActive(false);
	}
};