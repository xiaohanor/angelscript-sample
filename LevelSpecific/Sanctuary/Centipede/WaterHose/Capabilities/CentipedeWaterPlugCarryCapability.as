struct FCentipedeWaterPlugCarryCapabilityActivationParams
{
	ACentipedeWaterPlug WaterPlug = nullptr;
}

class UCentipedeWaterPlugCarryCapability : UHazePlayerCapability
{
	FCentipedeWaterPlugCarryCapabilityActivationParams Params;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerCentipedeComponent CentipedeComponent;
	UCentipedeBiteComponent CentipedeBiteComponent;

	FVector StartRelative;
	FHazeEasedVector EasedRelativeLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Player);
		CentipedeBiteComponent = UCentipedeBiteComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCentipedeWaterPlugCarryCapabilityActivationParams& ActivationParams) const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		UCentipedeBiteResponseComponent BittenComponent = CentipedeBiteComponent.GetBittenComponent();
		if (BittenComponent == nullptr)
			return false;

		ACentipedeWaterPlug CentipedeWaterPlug = Cast<ACentipedeWaterPlug>(BittenComponent.Owner);
		if (CentipedeWaterPlug == nullptr)
			return false;

		if (!CentipedeWaterPlug.bIsUnplugged)
			return false;

		ActivationParams.WaterPlug = CentipedeWaterPlug;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		if (!CentipedeBiteComponent.IsBitingSomething())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCentipedeWaterPlugCarryCapabilityActivationParams ActivationParams)
	{
		if (ActivationParams.WaterPlug == nullptr)
			return;

		Params = ActivationParams;
		Params.WaterPlug.SetActorControlSide(Player);
		Params.WaterPlug.AttachToActor(Player, NAME_None, EAttachmentRule::KeepWorld);
		StartRelative = Params.WaterPlug.ActorRelativeLocation;
		Params.WaterPlug.SetActorRelativeRotation(FRotator(0.0, 180, 0.0));
		Params.WaterPlug.BiteResponseComp.bDisabledAutoTargeting = true;
		UCentipedeMovementSettings::SetMoveSpeed(Player, 900.0 * 0.7, this);
		EasedRelativeLoc.ForceResetProgress();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Params.WaterPlug == nullptr)
			return;

		Params.WaterPlug.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Params.WaterPlug.LetGo();
		UCentipedeMovementSettings::ClearMoveSpeed(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		EasedRelativeLoc.EaseTo(StartRelative, Centipede::WaterPlugTargetRelativeLoc, 0.2, DeltaTime);
		Params.WaterPlug.SetActorRelativeLocation(EasedRelativeLoc.GetValue());
	}
}
