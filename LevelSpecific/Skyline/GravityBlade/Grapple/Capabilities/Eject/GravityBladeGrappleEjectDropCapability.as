class UGravityBladeGrappleEjectDropCapability : UHazeChildCapability
{
	default CapabilityTags.Add(GravityBladeTags::GravityBlade);

	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrapple);
	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrappleEject);
	default BlockExclusionTags.Add(GravityBladeGrappleTags::GravityBladeGrappleEject);

	default DebugCategory = GravityBlade::DebugCategory;

	AHazePlayerCharacter Player;
	UGravityBladeGrappleUserComponent GrappleComp;
	UGravityBladeGrappleEjectComponent EjectComp;
	float ActivateTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GrappleComp = UGravityBladeGrappleUserComponent::Get(Owner);
		EjectComp = UGravityBladeGrappleEjectComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActualActiveDuration > EjectComp.EjectData.DropDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UMovementGravitySettings::SetGravityScale(Player, 0.02, this);
		Player.ClearCameraSettingsByInstigator(GravityBladeGrapple::Eject::Instigator, 4.0);
		ActivateTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMovementGravitySettings::ClearGravityScale(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActualActiveDuration / EjectComp.EjectData.DropDuration);

		const float TimeDilation = Math::Lerp(EjectComp.EjectData.TimeDilation, 1, Alpha);
		Player.SetActorTimeDilation(TimeDilation, GravityBladeGrapple::Eject::Instigator);

		const float GravityScale = Math::Lerp(EjectComp.EjectData.GravityScale, 1, Alpha);
		UMovementGravitySettings::SetGravityScale(Player, GravityScale, this);
	}

	float GetActualActiveDuration() const property
	{
		return Time::GameTimeSeconds - ActivateTime;
	}
}