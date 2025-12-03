
class ATeenDragonAcidSprayAugmentVolume : APlayerTrigger
{
	default bTriggerLocally = true;

	UPROPERTY(EditAnywhere, Category = "Acid Spray")
	float AcidSprayRangeMultiplier = 1.0;
	UPROPERTY(EditAnywhere, Category = "Acid Spray")
	float AcidSprayStaminaMultiplier = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"VolumeEntered");
		OnPlayerLeave.AddUFunction(this, n"VolumeLeft");
	}

	UFUNCTION()
	private void VolumeEntered(AHazePlayerCharacter Player)
	{
		auto DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);
		if(DragonComp == nullptr)
			return;
		// auto Dragon = DragonComp.TeenDragon;
		// if(Dragon == nullptr)
		// 	return;
		auto SprayComp = UTeenDragonAcidSprayComponent::Get(Player);
		if (SprayComp != nullptr)
		{
			SprayComp.AcidSprayRangeMultiplier.Apply(AcidSprayRangeMultiplier, this);
			SprayComp.AcidSprayStaminaMultiplier.Apply(AcidSprayStaminaMultiplier, this);
		}
	}

	UFUNCTION()
	private void VolumeLeft(AHazePlayerCharacter Player)
	{
		auto DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);
		if(DragonComp == nullptr)
			return;
		// auto Dragon = DragonComp.TeenDragon;
		// if(Dragon == nullptr)
		// 	return;
		auto SprayComp = UTeenDragonAcidSprayComponent::Get(Player);
		if (SprayComp != nullptr)
		{
			SprayComp.AcidSprayRangeMultiplier.Clear(this);
			SprayComp.AcidSprayStaminaMultiplier.Clear(this);
		}
	}
};